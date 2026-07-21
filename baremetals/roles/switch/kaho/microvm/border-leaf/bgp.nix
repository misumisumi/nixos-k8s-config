{
  lib,
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
  inherit (static.microvm.borderLeaf) AS;
  inherit (config.networking.vxlan) tenants;

  physicalNetworks = filterAttrs (name: _: hasPrefix "15-" name) config.systemd.network.networks;
  underlayPrefixes = concatStringsSep "." (
    (sublist 0 3 (splitString "." tenants.tn1.L3VNI.local)) ++ [ "0/24" ]
  );
in
{
  networking.firewall = {
    extraInputRules = ''
      tcp dport bgp accept
      udp dport { bfd-control, bfd-echo } accept
      udp dport 4789 accept comment "VXLAN"
      ip protocol vrrp accept
    '';
  };
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

      ip prefix-list UNDERLAY_IPV4 permit ${underlayPrefixes} ge 32
      route-map SET-SRC permit 10
        match ip address prefix-list UNDERLAY_IPV4
        set src ${tenants.tn1.L3VNI.local}
      exit
      ip protocol bgp route-map SET-SRC

      route-map WCMP-MAP permit 10
        set extcommunity bandwidth num-multipaths
      exit

      vrf ${tenants.tn1.vrf}
        vni ${tenants.tn1.L3VNI.vni}
      exit-vrf

      router bgp ${AS}
        bgp router-id ${tenants.tn1.L3VNI.local}
        bgp log-neighbor-changes
        bgp bestpath as-path multipath-relax
        no bgp default ipv4-unicast

        neighbor SPINE peer-group
        neighbor SPINE bfd
        neighbor SPINE remote-as external
        neighbor SPINE advertisement-interval 0
        neighbor SPINE timers 3 9
        neighbor SPINE timers connect 10
        neighbor SPINE capability extended-nexthop
        ${concatMapStringsSep "\n  " (v: "neighbor ${v.name} interface peer-group SPINE") (
          attrValues physicalNetworks
        )}

        neighbor OVERLAY peer-group
        neighbor OVERLAY remote-as external
        neighbor OVERLAY advertisement-interval 0
        neighbor OVERLAY timers 3 9
        neighbor OVERLAY timers connect 10
        neighbor OVERLAY update-source lo0
        neighbor OVERLAY ebgp-multihop
        neighbor ${static.switch.sks8300-8x.routerId} peer-group OVERLAY
        neighbor ${static.switch.kaho.routerId} peer-group OVERLAY

        address-family ipv4 unicast
          redistribute connected route-map REDISTRIBUTE_LOOPBACK_INTERFACE
          neighbor SPINE activate
          neighbor SPINE route-map WCMP-MAP out
        exit-address-family

        address-family l2vpn evpn
          neighbor OVERLAY activate
          advertise-all-vni
          advertise-svi-ip
        exit-address-family

      router bgp ${AS} vrf ${tenants.tn1.vrf}
        address-family ipv4 unicast
          redistribute connected
        exit-address-family

        address-family l2vpn evpn
          advertise ipv4 unicast
        exit-address-family

      router bgp ${AS} vrf ${tenants.wan.vrf}
        bgp router-id ${tenants.wan.L3VNI.local}
        no bgp default ipv4-unicast

        neighbor ROUTER peer-group
        neighbor ROUTER bfd
        neighbor ROUTER remote-as external
        neighbor ROUTER advertisement-interval 0
        neighbor ROUTER timers 3 9
        neighbor ROUTER timers connect 10
        neighbor ROUTER capability extended-nexthop
        neighbor enp0s3 interface peer-group ROUTER

        neighbor OVERLAY peer-group
        neighbor OVERLAY remote-as external
        neighbor OVERLAY advertisement-interval 0
        neighbor OVERLAY timers 3 9
        neighbor OVERLAY timers connect 10
        neighbor OVERLAY update-source lo${tenants.wan.L3VNI.vni}
        neighbor OVERLAY ebgp-multihop
        neighbor ${static.microvm.borderRouter.routerId} peer-group OVERLAY

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
