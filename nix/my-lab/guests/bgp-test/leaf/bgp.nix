{
  lib,
  config,
  switch_id,
  ...
}:
let
  inherit (builtins) head match;
  inherit (lib)
    concatMapStringsSep
    mapAttrsToList
    filterAttrs
    hasPrefix
    ;
  physicalNetworks = filterAttrs (name: _: hasPrefix "10-" name) config.systemd.network.networks;
  IFIPs = mapAttrsToList (
    _: config: "${head (match "(.*).[[:didit:]]/.*" (head config.address))}"
  ) physicalNetworks;
  neighborConfig = group: concatMapStringsSep "\n  " (ip: "neighbor ${ip} peer-group ${group}") IFIPs;
  # ${neighborConfig "SPINE"}
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

      route-map UNDERLAY_ANYCAST_IP permit 10
        match ip address prefix-list UNDERLAY_SUBNET
        set extcommunity bandwidth cumulative
      exit

      vrf vrf10001
        vni 10001
      exit-vrf
      vrf vrf10002
        vni 10002
      exit-vrf

      router bgp 6500${switch_id}
        bgp router-id 10.1.254.${switch_id}
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
        neighbor enp6s0 interface peer-group SPINE
        neighbor enp7s0 interface peer-group SPINE

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

      router bgp 6500${switch_id} vrf vrf10001
        address-family ipv4 unicast
          redistribute connected
        exit-address-family

        address-family l2vpn evpn
          advertise ipv4 unicast
        exit-address-family

      router bgp 6500${switch_id} vrf vrf10002
        address-family ipv4 unicast
          redistribute connected
        exit-address-family

        address-family l2vpn evpn
          advertise ipv4 unicast
        exit-address-family
    '';
  };
}
