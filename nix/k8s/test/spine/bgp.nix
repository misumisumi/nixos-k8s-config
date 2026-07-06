{ lib, config, ... }:
let
  inherit (builtins) attrValues;
  inherit (lib)
    concatMapStringsSep
    filterAttrs
    hasPrefix
    ;
  routerId = "10.10.10.10";
  underlayPrefixes = "10.10.10.0/24";

  physicalNetworks = filterAttrs (name: _: hasPrefix "15-" name) config.systemd.network.networks;
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
  networking.firewall = {
    extraInputRules = ''
      tcp dport bgp accept
      udp dport { bfd-control, bfd-echo } accept
      udp dport 4789 accept comment "VXLAN"
      ip protocol vrrp accept
    '';
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

      route-map WCMP-MAP permit 10
        set extcommunity bandwidth 40
      exit

      router bgp 65000
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
        bgp listen range ${underlayPrefixes} peer-group OVERLAY

        address-family ipv4 unicast
          redistribute connected route-map REDISTRIBUTE_LOOPBACK_INTERFACE
          neighbor LEAF activate
          neighbor LEAF route-map WCMP-MAP out
          maximum-paths 64
        exit-address-family

        address-family l2vpn evpn
          neighbor OVERLAY activate
          advertise-all-vni
        exit-address-family
    '';
  };
}
