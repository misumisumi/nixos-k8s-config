{
  lib,
  config,
  static,
  ...
}:
let
  inherit (builtins)
    attrValues
    length
    ;
  inherit (lib)
    concatStringsSep
    concatMapStringsSep
    filterAttrs
    hasPrefix
    imap1
    splitString
    sublist
    ;
  inherit (static.microvm.homeLeaf.bgp) AS;
  inherit (config.networking.vxlan) tenants;

  # ゾーン = DHCP を提供するテナント (wan を除く)
  zones = filterAttrs (n: _: n != "wan") tenants;
  zoneList = attrValues zones;

  localVnis = map (z: z.L3VNI.vni) zoneList;

  # 自 VNI の default のみ許可し、他 VNI の default は一括で拒否する。
  # 新しいテナントが増えても foreign VNI の列挙は不要 (fail-closed)。
  egressFilterPermits = imap1 (i: vni: ''
    route-map EGRESS_DEFAULT_FILTER permit ${toString (i * 10)}
      match evpn vni ${toString vni}
      match evpn default-route
    exit
  '') localVnis;
  egressFilterDenySeq = (length localVnis + 1) * 10;
  egressFilterDeny = ''
    route-map EGRESS_DEFAULT_FILTER deny ${toString egressFilterDenySeq}
      match evpn default-route
    exit
    route-map EGRESS_DEFAULT_FILTER permit ${toString (egressFilterDenySeq + 10)}
    exit
  '';

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

  # ゾーンごとの VRF BGP インスタンス (ゾーン間 leak はしない)
  # WAN egress の default は border-leaf の EVPN type-5 から学習する
  # svc VRF (L3VNI 10001) のルートを import し、egress で downstream VNI
  # (VNI 10001) を指定してカプセル化する。
  # NOTE: route-target import auto はゾーン自身の auto RT を維持するために必要
  #       (手動 RT のみ設定すると auto RT が外れる)。auto を先に設定すること。
  zoneRouterBlocks = concatMapStringsSep "\n" (z: ''
    router bgp ${AS} vrf ${z.vrf}
      address-family ipv4 unicast
        redistribute connected
      exit-address-family

      address-family l2vpn evpn
        advertise ipv4 unicast
        route-target import auto
        route-target import *:10001
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

      ip prefix-list UNDERLAY_IPV4 permit ${underlayPrefixes} ge 32
      route-map SET-SRC permit 10
        match ip address prefix-list UNDERLAY_IPV4
        set src ${tenants.home.L3VNI.local}
      exit
      ip protocol bgp route-map SET-SRC

      route-map WCMP-MAP permit 10
        set extcommunity bandwidth num-multipaths
      exit

      ${concatStringsSep "\n" egressFilterPermits}
      ${egressFilterDeny}

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
          neighbor OVERLAY route-map EGRESS_DEFAULT_FILTER in
          advertise-all-vni
          advertise-svi-ip
        exit-address-family

      ${zoneRouterBlocks}
    '';
  };
}
