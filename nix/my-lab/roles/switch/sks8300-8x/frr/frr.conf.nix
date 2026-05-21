{
  lib,
  writeText,
  static,
}:
let
  inherit (lib)
    concatStringsSep
    splitString
    sublist
    ;
  inherit (static.switch.sks8300-8x)
    hostname
    routerId
    AS
    l2vpnListenRange
    ;

  underlayPrefixes = concatStringsSep "." ((sublist 0 3 (splitString "." routerId)) ++ [ "0/24" ]);
in
writeText "frr.conf" ''
  hostname ${hostname}
  log syslog
  service password-encryption
  service integrated-vtysh-config
  !
  frr defaults datacenter
  log syslog informational

  route-map REDISTRIBUTE_LOOPBACK_INTERFACE permit 10
    match interface lo
  exit

  ip prefix-list UNDERLAY_IPV4 permit ${underlayPrefixes} ge 32
  route-map SET-SRC permit 10
    match ip address prefix-list UNDERLAY_IPV4
    set src ${routerId}
  exit
  ip protocol bgp route-map SET-SRC

  route-map WCMP-MAP permit 10
    set extcommunity bandwidth 40
  exit

  router bgp ${AS}
    bgp router-id ${routerId}
    bgp log-neighbor-changes
    bgp bestpath as-path multipath-relax
    no bgp default ipv4-unicast
    neighbor LEAF peer-group
    neighbor LEAF bfd
    neighbor LEAF remote-as external
    neighbor LEAF advertisement-interval 0
    neighbor LEAF timers 3 9
    neighbor LEAF timers connect 10
    neighbor LEAF capability extended-nexthop
    neighbor eth1 interface peer-group LEAF
    neighbor eth2 interface peer-group LEAF
    neighbor eth3 interface peer-group LEAF
    neighbor eth4 interface peer-group LEAF

    neighbor OVERLAY peer-group
    neighbor OVERLAY remote-as external
    neighbor OVERLAY advertisement-interval 0
    neighbor OVERLAY timers 3 9
    neighbor OVERLAY timers connect 10
    neighbor OVERLAY update-source lo
    neighbor OVERLAY ebgp-multihop
    bgp listen range ${l2vpnListenRange} peer-group OVERLAY

    address-family ipv4 unicast
      redistribute connected route-map REDISTRIBUTE_LOOPBACK_INTERFACE
      neighbor LEAF activate
      neighbor LEAF route-map WCMP-MAP out
      maximum-paths 64
    exit-address-family

    address-family l2vpn evpn
      neighbor OVERLAY activate
      advertise-all-vni
    exit-address-family

  !
  end
''
