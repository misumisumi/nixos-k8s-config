{
  lib,
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

      router bgp 65001
        bgp router-id 10.0.254.1
        bgp log-neighbor-changes
        bgp bestpath as-path multipath-relax
        no bgp default ipv4-unicast
        neighbor LEAF peer-group
        neighbor LEAF bfd
        neighbor LEAF advertisement-interval 0
        neighbor LEAF timers 1 3
        neighbor LEAF timers connect 5
        neighbor LEAF capability extended-nexthop
        neighbor LEAF remote-as external
        bgp listen range 192.168.0.0/16 peer-group LEAF

        address-family ipv4 unicast
          network 10.0.254.1/32
          neighbor LEAF activate
          maximum-paths 64
        exit-address-family
    '';
    # neighbor LEAF update-source Loopback0.0
    # neighbor LEAF ebgp-multihop 2
    # address-family ipv4 unicast
    #   redistribute connected route-map REDISTRIBUTE_LOOPBACK_INTERFACE
    #   neighbor LEAF activate
    # exit-address-family
  };
}
