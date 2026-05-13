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

  inherit (config.networking.vxlan) tenants;
  inherit (static.${group}.${hostname}) AS;
  inherit (static.${group}) virtualIPs;

  physicalNetworks = filterAttrs (name: _: hasPrefix "15-" name) config.systemd.network.networks;
  underlayPrefixList = concatStringsSep "." (
    (sublist 0 3 (splitString "." tenants.tn1.L3VNI.local)) ++ [ "0/24" ]
  );
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

      ip prefix-list UNDERLAY_IPV4 permit ${underlayPrefixList} ge 32

      route-map SET-SRC permit 10
        match ip address prefix-list UNDERLAY_IPV4
        set src ${tenants.tn1.L3VNI.local}
      exit

      route-map UNDERLAY_ANYCAST_IP permit 10
        match ip address prefix-list UNDERLAY_SUBNET
        set extcommunity bandwidth cumulative
      exit

      vrf ${tenants.tn1.vrf}
        vni ${toString tenants.tn1.L3VNI.vni}
      exit-vrf

      ip protocol bgp route-map SET-SRC

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
        neighbor ${static.switch.sks8300.routerId} peer-group OVERLAY
        neighbor ${static.switch.kaho.routerId} peer-group OVERLAY

        address-family ipv4 unicast
          network ${virtualIPs.linstor.address}/${virtualIPs.linstor.cidr}
          network ${virtualIPs.nfs.address}/${virtualIPs.nfs.cidr}
          redistribute connected route-map REDISTRIBUTE_LOOPBACK_INTERFACE
          neighbor SPINE activate
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
    '';
    # network ${virtualIPs.incus.address}/${virtualIPs.incus.cidr}
    # network ${config.linkage.highAvailable.virtualIP.address}/${config.linkage.highAvailable.virtualIP.cidr}
  };
}
