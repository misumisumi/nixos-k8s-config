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

  inherit (config.networking.vxlan) tenants;
  inherit (static.microvm.borderRouter.bgp) AS;

  # ゾーン = テナント (wan を除く)
  zones = filterAttrs (n: _: n != "wan") tenants;
  zoneList = attrValues zones;

  physicalNetworks = filterAttrs (name: _: hasPrefix "15-" name) config.systemd.network.networks;
  underlayPrefixes = concatStringsSep "." (
    (sublist 0 3 (splitString "." tenants.home.L3VNI.local)) ++ [ "0/24" ]
  );

  # ゾーンごとの VRF 宣言
  vrfDecls = concatMapStringsSep "\n" (z: ''
    vrf ${z.vrf}
      vni ${toString z.L3VNI.vni}
    exit-vrf
  '') zoneList;

  # ゾーンごとの VRF BGP インスタンス。
  # WAN (wan-vrf30001) の default を import し、EVPN type-5 で各 VTEP へ広報する。
  zoneRouterBlocks = concatMapStringsSep "\n" (z: ''
    router bgp ${AS} vrf ${z.vrf}
      address-family ipv4 unicast
        redistribute connected
        import vrf ${tenants.wan.vrf}
      exit-address-family

      address-family l2vpn evpn
        advertise ipv4 unicast
      exit-address-family
  '') zoneList;
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
  # FRR (Free Range Routing) を有効にする
  services.frr = {
    bgpd.enable = true;
    bfdd.enable = true;
    config = ''
      frr defaults datacenter
      log syslog informational

      route-map REDISTRIBUTE_LOOPBACK_INTERFACE permit 10
        match interface lo0
      exit

      ip prefix-list UNDERLAY_IPV4 permit ${underlayPrefixes} ge 32
      route-map SET-SRC permit 10
        match ip address prefix-list UNDERLAY_IPV4
        set src ${tenants.home.L3VNI.local}
      exit
      ip protocol bgp route-map SET-SRC

      route-map WCMP-MAP permit 10
        set extcommunity bandwidth num-multipaths
      exit

      ${vrfDecls}

      router bgp ${AS}
        bgp router-id ${tenants.home.L3VNI.local}
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
        neighbor ${static.switch.sks8300-8x.bgp.routerId} peer-group OVERLAY
        neighbor ${static.switch.kaho.bgp.routerId} peer-group OVERLAY

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

      ${zoneRouterBlocks}

      router bgp ${AS} vrf ${tenants.wan.vrf}
        bgp router-id ${tenants.wan.L3VNI.local}
        address-family ipv4 unicast
          redistribute kernel
          redistribute connected
          # NAT の戻り (DNAT 後の応答) を wan VRF から tenant VRF へ配送するため leak する
          ${concatMapStringsSep "\n          " (z: "import vrf ${z.vrf}") zoneList}
        exit-address-family
    '';
  };
}
