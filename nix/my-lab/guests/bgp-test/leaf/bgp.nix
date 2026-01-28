{
  switch_id,
  ...
}:

{
  # FRR (Free Range Routing) を有効にする
  services.frr = {
    bgpd.enable = true;
    # FRRの設定はconfigオプションで直接記述
    config = ''
      frr defaults datacenter
      log syslog informational

      ip prefix-list UNDERLAY_SUBNET seq 10 permit 10.0.254.0/24 le 32

      route-map ACCEPT_UNDERLAY_ADDRESSES permit 10
        match ip address prefix-list UNDERLAY_SUBNET
      exit

      route-map UNDERLAY_ANYCAST_IP permit 10
        match interface enp5s0
        set extcommunity bandwidth cumulative
      exit

      router bgp 6500${switch_id}
        bgp router-id 10.0.254.${switch_id}
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
        neighbor enp5s0 interface peer-group SPINE
        neighbor enp6s0 interface peer-group SPINE
        neighbor enp7s0.${switch_id} interface peer-group SPINE

        address-family ipv4 unicast
          network 10.0.254.${switch_id}/32
          neighbor SPINE activate
        exit-address-family

        neighbor EVPN peer-group
        neighbor EVPN remote-as external
        neighbor EVPN ebgp-multihop 2
        neighbor EVPN update-source lo

        address-family l2vpn evpn
          advertise-all-vni
          advertise-svi-ip
        exit-address-family
    '';
    # address-family ipv4 unicast
    #   redistribute connected route-map ACCEPT_UNDERLAY_ADDRESSES
    #   neighbor SPINE activate
    #   neighbor SPINE route-map UNDERLAY_ANYCAST_IP out
    #   maximum-paths 64
    # exit-address-family
  };
}
