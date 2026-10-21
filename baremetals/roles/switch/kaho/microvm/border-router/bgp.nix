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

  # ゾーン = EVPN type-5 で広報するテナント (wan と svc を除く)
  zones = filterAttrs (n: _: n != "wan" && n != "svc") tenants;
  zoneList = attrValues zones;

  # VRF 宣言と wan への leak 対象となる全テナント (svc を含む)
  tenantVrfs = attrValues (filterAttrs (n: _: n != "wan") tenants);

  physicalNetworks = filterAttrs (name: _: hasPrefix "15-" name) config.systemd.network.networks;
  underlayPrefixes = concatStringsSep "." (
    (sublist 0 3 (splitString "." tenants.home.L3VNI.local)) ++ [ "0/24" ]
  );

  # ゾーンごとの VRF 宣言
  vrfDecls = concatMapStringsSep "\n" (z: ''
    vrf ${z.vrf}
      vni ${toString z.L3VNI.vni}
    exit-vrf
  '') tenantVrfs;

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

  # svc VRF の BGP インスタンス (border-router 側)。
  # WAN default を import し、EVPN type-5 で広報して svc-leaf に再帰経路 (デフォルト) を
  # 提供する。ゾーン (home 等) のサブネットは svc-leaf が route-target import で直接
  # 学習するため、border 側では import しない (テナント間を border 経由させない)。
  svcRouterBlock = ''
    router bgp ${AS} vrf ${tenants.svc.vrf}
      address-family ipv4 unicast
        redistribute connected
        import vrf ${tenants.wan.vrf}
      exit-address-family

      address-family l2vpn evpn
        advertise ipv4 unicast
      exit-address-family
  '';
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

      # import vrf で wan VRF へ leak する際、/32 host route (advertise-svi-ip / ARP 由来の
      # EVPN type-2) を除外する。leak された /32 は nexthop が他 VRF のデバイス
      # (dev <tenant>-vniXXXX) となり forward 不可で、/24 aggregate (dev <tenant>-vrfXXXX,
      # forward 可) を LPM で shadow してしまうため、集約 (/0..31) のみ通す。
      ip prefix-list LEAK_NO_HOST32 deny 0.0.0.0/0 ge 32
      ip prefix-list LEAK_NO_HOST32 permit 0.0.0.0/0 le 31

      route-map FILTER_HOST32 permit 10
        match ip address prefix-list LEAK_NO_HOST32
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

      ${svcRouterBlock}

      router bgp ${AS} vrf ${tenants.wan.vrf}
        bgp router-id ${tenants.wan.L3VNI.local}
        address-family ipv4 unicast
          redistribute kernel
          redistribute connected
          # NAT の戻り (DNAT 後の応答) を wan VRF から tenant VRF へ配送するため leak する。
          # FILTER_HOST32 で /32 host route を除外し /24 aggregate のみ取り込む。
          import vrf route-map FILTER_HOST32
          ${concatMapStringsSep "\n          " (z: "import vrf ${z.vrf}") tenantVrfs}
        exit-address-family
    '';
  };
}
