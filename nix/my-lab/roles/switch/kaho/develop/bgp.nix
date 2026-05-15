{
  lib,
  hostname,
  group,
  config,
  static,
  ...
}:
let
  inherit (builtins) attrValues;
  inherit (lib)
    concatStringsSep
    concatMapStringsSep
    filterAttrs
    hasPrefix
    splitString
    sublist
    ;

  inherit (static.${group}.${hostname}) AS routerId l2vpnListenRange;
  physicalNetworks = filterAttrs (name: _: hasPrefix "15-" name) config.systemd.network.networks;
  underlayPrefixes = concatStringsSep "." ((sublist 0 3 (splitString "." routerId)) ++ [ "0/24" ]);
in
{
  systemd.network = {
    config.networkConfig = {
      #NOTE: https://scottstuff.net/posts/2025/02/25/frr-vs-systemd-networkd/
      ManageForeignNextHops = false;
      ManageForeignRoutes = false;
      ManageForeignRoutingPolicyRules = false;
    };
  };
  # FRR (Free Range Routing) を有効にする
  services.frr = {
    bgpd.enable = true;
    bfdd.enable = true;
    # FRRの設定はconfigオプションで直接記述
    #NOTE: IBはL2スイッチなので、アンダーレイにはスタティックルートを使う
    config = ''
      frr defaults datacenter
      log syslog informational

      route-map REDISTRIBUTE_LOOPBACK_INTERFACE permit 10
        match interface lo0
      exit

      ip prefix-list UNDERLAY_IPV4 permit ${underlayPrefixes} ge 32
      route-map SET-SRC permit 10
        match ip address prefix-list UNDERLAY_IPV4
        set src ${routerId}
      exit
      ip protocol bgp route-map SET-SRC

      router bgp ${AS}
        bgp router-id ${routerId}
        bgp log-neighbor-changes
        bgp bestpath as-path multipath-relax
        no bgp default ipv4-unicast
        neighbor LEAF peer-group
        neighbor LEAF bfd
        neighbor LEAF remote-as external
        neighbor LEAF advertisement-interval 0
        neighbor LEAF timers 3 9
        neighbor LEAF timers connect 10
        neighbor LEAF capability extended-nexthop
        ${concatMapStringsSep "\n  " (v: "neighbor ${v.name} interface peer-group LEAF") (
          attrValues physicalNetworks
        )}

        neighbor OVERLAY peer-group
        neighbor OVERLAY remote-as external
        neighbor OVERLAY advertisement-interval 0
        neighbor OVERLAY timers 3 9
        neighbor OVERLAY timers connect 10
        neighbor OVERLAY update-source lo0
        neighbor OVERLAY ebgp-multihop
        bgp listen range ${l2vpnListenRange} peer-group OVERLAY

        address-family ipv4 unicast
          redistribute connected route-map REDISTRIBUTE_LOOPBACK_INTERFACE
          neighbor LEAF activate
          maximum-paths 64
        exit-address-family

        address-family l2vpn evpn
          neighbor OVERLAY activate
          advertise-all-vni
        exit-address-family
    '';
  };
}
