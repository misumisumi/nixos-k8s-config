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

      route-map REDISTRIBUTE_WAN_INTERFACE permit 10
        match interface enp0s5
      exit

      route-map UNDERLAY_ANYCAST_IP permit 10
        match ip address prefix-list UNDERLAY_SUBNET
        set extcommunity bandwidth cumulative
      exit

      vrf ${tenants.tn1.vrf}
        vni ${toString tenants.tn1.L3VNI.vni}
      exit-vrf

      vrf vrf91001
        vni 91001
      exit-vrf

      router bgp 65101
        bgp router-id 10.1.254.253
        bgp log-neighbor-changes
        bgp bestpath as-path multipath-relax
        no bgp default ipv4-unicast

        neighbor SPINE peer-group
        neighbor SPINE bfd
        neighbor SPINE remote-as external
        neighbor SPINE advertisement-interval 0
        neighbor SPINE timers 1 3
        neighbor SPINE timers connect 5
        neighbor SPINE capability extended-nexthop
        ${concatMapStringsSep "\n  " (v: "neighbor ${v.name} interface peer-group SPINE") (
          attrValues physicalNetworks
        )}

        neighbor OVERLAY peer-group
        neighbor OVERLAY remote-as external
        neighbor OVERLAY advertisement-interval 0
        neighbor OVERLAY timers 1 3
        neighbor OVERLAY timers connect 5
        neighbor OVERLAY update-source lo0
        neighbor OVERLAY ebgp-multihop
        neighbor 10.1.254.1 peer-group OVERLAY
        neighbor 10.1.254.2 peer-group OVERLAY

        address-family ipv4 unicast
          redistribute connected route-map REDISTRIBUTE_LOOPBACK_INTERFACE
          neighbor SPINE activate
        exit-address-family

        address-family l2vpn evpn
          neighbor OVERLAY activate
          advertise-all-vni
          advertise-svi-ip
        exit-address-family

      router bgp 65101 vrf vrf10001
        address-family ipv4 unicast
          redistribute connected
        exit-address-family

        address-family l2vpn evpn
          advertise ipv4 unicast
        exit-address-family

      router bgp 65101 vrf vrf91001
        bgp router-id 10.1.254.253
        no bgp default ipv4-unicast

        neighbor ROUTER peer-group
        neighbor ROUTER bfd
        neighbor ROUTER remote-as external
        neighbor ROUTER advertisement-interval 0
        neighbor ROUTER timers 1 3
        neighbor ROUTER timers connect 5
        neighbor ROUTER capability extended-nexthop
        neighbor enp0s5 interface peer-group ROUTER

        neighbor OVERLAY peer-group
        neighbor OVERLAY remote-as external
        neighbor OVERLAY advertisement-interval 0
        neighbor OVERLAY timers 1 3
        neighbor OVERLAY timers connect 5
        neighbor OVERLAY update-source lo91001
        neighbor OVERLAY ebgp-multihop
        neighbor 10.1.254.254 peer-group OVERLAY

        address-family ipv4 unicast
          redistribute connected
          neighbor ROUTER activate
        exit-address-family

        address-family l2vpn evpn
          advertise ipv4 unicast
          neighbor OVERLAY activate
        exit-address-family
    '';
  };
}
