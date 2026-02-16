{
  lib,
  switch_id,
  ...
}:
let
  inherit (lib) concatMapStringsSep range;
in
{
  # FRR (Free Range Routing) を有効にする
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

      router bgp 65001
        bgp router-id 10.1.254.${switch_id}
        bgp log-neighbor-changes
        bgp bestpath as-path multipath-relax
        no bgp default ipv4-unicast
        neighbor LEAF peer-group
        neighbor LEAF bfd
        neighbor LEAF remote-as external
        neighbor LEAF advertisement-interval 0
        neighbor LEAF timers 1 3
        neighbor LEAF timers connect 5
        neighbor LEAF capability extended-nexthop
        ${concatMapStringsSep "\n  " (x: "neighbor enp${toString x}s0 interface peer-group LEAF") (
          range 5 8
        )}

        neighbor OVERLAY peer-group
        neighbor OVERLAY remote-as external
        neighbor OVERLAY advertisement-interval 0
        neighbor OVERLAY timers 1 3
        neighbor OVERLAY timers connect 5
        neighbor OVERLAY update-source lo0
        neighbor OVERLAY ebgp-multihop
        bgp listen range 10.1.254.0/24 peer-group OVERLAY
        bgp listen range 10.254.254.0/30 peer-group OVERLAY

        address-family ipv4 unicast
          redistribute connected route-map REDISTRIBUTE_LOOPBACK_INTERFACE
          neighbor LEAF activate
          maximum-paths 64
        exit-address-family

        address-family l2vpn evpn
          neighbor OVERLAY activate
          advertise-all-vni
        exit-address-family
    '';
    # bgp listen range 192.168.0.0/16 peer-group LEAF
  };
}
