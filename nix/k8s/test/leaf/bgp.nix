{ lib, config, ... }:
let
  inherit (builtins) attrValues;
  inherit (lib)
    concatMapStringsSep
    filterAttrs
    hasPrefix
    ;
  inherit (config.networking.vxlan) tenants;

  routerId = "10.10.10.50";
  underlayPrefixes = "10.10.10.0/24";
  k8sNodeIpRange = "172.16.100.0/24";

  physicalNetworks = filterAttrs (name: _: hasPrefix "15-" name) config.systemd.network.networks;
in
{
  systemd.network = {
    config.networkConfig = {
      #NOTE: https://scottstuff.net/posts/2025/02/25/frr-vs-systemd-networkd/
      ManageForeignNextHops = false;
      ManageForeignRoutes = false;
      ManageForeignRoutingPolicyRules = false;
    };
  };
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
    # FRRの設定はconfigオプションで直接記述
    #NOTE: IBはL2スイッチなので、アンダーレイにはスタティックルートを使う
    config = ''
      frr defaults datacenter
      log syslog informational

      route-map REDISTRIBUTE_LOOPBACK_INTERFACE permit 10
        match interface lo0
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

      router bgp 65100
        bgp router-id ${routerId}
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
        neighbor 10.10.10.10 peer-group OVERLAY

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

      router bgp 65200 vrf ${tenants.k8s.vrf}
        bgp router-id ${routerId}
        bgp log-neighbor-changes
        bgp bestpath as-path multipath-relax
        no bgp default ipv4-unicast
        neighbor K8S peer-group
        neighbor K8S bfd
        neighbor K8S remote-as external
        neighbor K8S advertisement-interval 0
        neighbor K8S timers 3 9
        neighbor K8S timers connect 10
        neighbor K8S capability extended-nexthop
        bgp listen range ${k8sNodeIpRange} peer-group K8S

        address-family ipv4 unicast
          redistribute connected
          neighbor K8S activate
        exit-address-family

        address-family l2vpn evpn
          advertise ipv4 unicast
        exit-address-family
    '';
  };
}
