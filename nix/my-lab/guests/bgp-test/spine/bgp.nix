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

      route-map REDISTRIBUTE_LOOPBACK_INTERFACE permit 10
        match interface lo0
      exit

      router bgp 65001
        bgp router-id 10.0.254.${switch_id}
        bgp log-neighbor-changes
        bgp bestpath as-path multipath-relax
        bgp bestpath bandwidth skip-missing
        no bgp default ipv4-unicast
        neighbor LEAF peer-group
        neighbor LEAF bfd
        neighbor LEAF remote-as external
        neighbor LEAF advertisement-interval 0
        neighbor LEAF timers 1 3
        neighbor LEAF timers connect 5
        neighbor LEAF capability extended-nexthop
        neighbor enp5s0 interface peer-group LEAF
        neighbor enp6s0 interface peer-group LEAF
        neighbor enp7s0 interface peer-group LEAF
        neighbor enp8s0 interface peer-group LEAF

        address-family ipv4 unicast
          redistribute connected route-map REDISTRIBUTE_LOOPBACK_INTERFACE
          neighbor LEAF activate
          maximum-paths 64
        exit-address-family
    '';
  };
}
