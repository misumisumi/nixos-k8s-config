{
  lib,
  config,
  ...
}:
let
  inherit (builtins) attrValues;
  inherit (lib)
    concatMapStringsSep
    filterAttrs
    hasPrefix
    ;
  physicalNetworks = filterAttrs (name: _: hasPrefix "15-" name) config.systemd.network.networks;
  inherit (config.networking.vxlan) tenants;
in
{
  systemd.network.config.networkConfig = {
    #NOTE: https://scottstuff.net/posts/2025/02/25/frr-vs-systemd-networkd/
    ManageForeignNextHops = false;
    ManageForeignRoutes = false;
    ManageForeignRoutingPolicyRules = false;
  };
  # FRR (Free Range Routing) を有効にする
  # systemd.services.frr.wantedBy = lib.mkForce [ ];
  services.frr = {
    bgpd.enable = true;
    bfdd.enable = true;
    # FRRの設定はconfigオプションで直接記述
    config = ''
      frr defaults datacenter
      log syslog informational

      route-map REDISTRIBUTE_LOOPBACK_INTERFACE permit 10
        match interface lo0
      exit

      ip prefix-list only_default seq 1 permit 0.0.0.0/0
      route-map MAP_VTEP_IN deny 1
        match ip address prefix-list only_default
      exit
      route-map MAP_VTEP_IN permit 3
      exit

      route-map MAP_VTEP_OUT permit 1
      exit

      router bgp 64601
        bgp router-id 10.1.254.254
        bgp log-neighbor-changes
        bgp bestpath as-path multipath-relax
        no bgp default ipv4-unicast

        neighbor BORDER peer-group
        neighbor BORDER remote-as external
        neighbor BORDER advertisement-interval 0
        neighbor BORDER timers 1 3
        neighbor BORDER timers connect 5
        neighbor BORDER capability extended-nexthop
        ${concatMapStringsSep "\n  " (v: "neighbor ${v.name} interface peer-group BORDER") (
          attrValues physicalNetworks
        )}

        neighbor OVERLAY peer-group
        neighbor OVERLAY remote-as external
        neighbor OVERLAY advertisement-interval 0
        neighbor OVERLAY timers 1 3
        neighbor OVERLAY timers connect 5
        neighbor OVERLAY update-source lo0
        neighbor OVERLAY ebgp-multihop
        neighbor 10.1.254.253 peer-group OVERLAY

        address-family ipv4 unicast
          redistribute connected route-map REDISTRIBUTE_LOOPBACK_INTERFACE
          neighbor BORDER activate
        exit-address-family

        address-family l2vpn evpn
          neighbor OVERLAY activate
          advertise ipv4 unicast
          redistribute kernel
        exit-address-family
    '';
    # neighbor 10.2.254.1 peer-group BORDER
  };
}
