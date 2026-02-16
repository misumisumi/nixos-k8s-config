{
  lib,
  config,
  ...
}:
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

      ip prefix-list only_default seq 1 permit 0.0.0.0/0
      route-map MAP_VTEP_IN deny 1
        match ip address prefix-list only_default
      exit
      route-map MAP_VTEP_IN permit 3
      exit

      route-map MAP_VTEP_OUT permit 1
      exit

      vrf vrf91001
        vni 91001
      exit-vrf

      router bgp 64601
        bgp router-id 10.254.254.1
        bgp log-neighbor-changes
        bgp bestpath as-path multipath-relax
        no bgp default ipv4-unicast

        neighbor BORDER peer-group
        neighbor BORDER remote-as external
        neighbor BORDER advertisement-interval 0
        neighbor BORDER timers 1 3
        neighbor BORDER timers connect 5
        neighbor BORDER capability extended-nexthop
        neighbor 192.168.255.2 peer-group BORDER

        address-family ipv4 unicast
          neighbor BORDER activate
          redistribute kernel
        exit-address-family
    '';
  };
}
