{
  lib,
  static,
  config,
  ...
}:
let
  inherit (config.networking.vxlan) tenants;
  inherit (static.microvm.borderRouter.bgp) routerId wanVrfTable;
  # WAN は冗長化しないため EVPN (L3VNI) にせず、tenant VRF へ `import vrf` で
  # default を leak する VRF-lite 構成にする。VRF だけを単独で定義する。
  wanVrf = "wan-vrf${toString wanVrfTable}";
in
{
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.default.rp_filter" = 0;
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv6.conf.default.forwarding" = 1;
  };
  networking = {
    firewall.enable = true;
    nftables.enable = true;
    hostName = "router";
    useNetworkd = true;
    useDHCP = false;
    # border の各 VRF (wan/home/svc) から到達できる public DNS を使う。
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };
  # systemd-resolved の stub (127.0.0.53) は VRF 内から到達できない。
  services.resolved.enable = false;
  networking.vxlan.tenants = {
    # 家庭内ネットワーク。1 つの L3 VNI (11001) に LAN/IoT/Guest を VLAN で集約する。
    "home" = {
      name = "home";
      L3VNI = {
        hwAddr = "3E:E9:45:18:AD:4B";
        vni = 11001;
        vlan = 1101;
        local = routerId;
        destinationPort = 4789;
        # border は tenant VRF を終端する PE。L2 access port を持たないため
        # L2VNI/VLAN pair を持たず L3VNI のみを構成する。
        mode = "l3-only";
      };
    };
    # service テナント。DNS リゾルバ (svc-leaf のコンテナ) の戻り経路と
    # 外部への再帰経路 (wan VRF への leak / NAT) を提供する。
    "svc" = {
      name = "svc";
      L3VNI = {
        hwAddr = "3E:E9:45:18:AD:52";
        vni = 10001;
        vlan = 1001;
        local = routerId;
        destinationPort = 4789;
        mode = "l3-only";
      };
    };
  };
  systemd.network = {
    config.networkConfig = {
      #NOTE: https://scottstuff.net/posts/2025/02/25/frr-vs-systemd-networkd/
      ManageForeignNextHops = false;
      ManageForeignRoutes = false;
      ManageForeignRoutingPolicyRules = false;
    };
    netdevs = {
      lo0 = {
        netdevConfig = {
          Name = "lo0";
          Kind = "dummy";
        };
      };
      "${wanVrf}" = {
        netdevConfig = {
          Name = "${wanVrf}";
          Kind = "vrf";
          Description = "VRF for wan";
        };
        vrfConfig = {
          Table = wanVrfTable;
        };
      };
      "lo${toString wanVrfTable}" = {
        netdevConfig = {
          Name = "lo${toString wanVrfTable}";
          Kind = "dummy";
        };
      };
    };
    networks = {
      "5-lo0" = {
        name = "lo0";
        address = [
          "${tenants.home.L3VNI.local}/32"
        ];
      };
      # wan VRF の VRF デバイス。tenant VRF から `import vrf` するだけなので
      # アドレスやブリッジは持たない。
      "50-${wanVrf}" = {
        name = "${wanVrf}";
      };
      "5-lo${toString wanVrfTable}" = {
        name = "lo${toString wanVrfTable}";
        vrf = [ "${wanVrf}" ];
        address = [
          "${tenants.home.L3VNI.local}/32"
        ];
      };
      # BGP unnumbered の underlay リンク (ホスト側 br_router2host)
      "15-host" = {
        name = static.microvm.borderRouter.networks.host.IF;
        linkConfig = {
          MTUBytes = static.microvm.borderRouter.mtu;
        };
        networkConfig = {
          Description = "To host interface (BGP unnumbered underlay)";
          IPv6AcceptRA = false;
        };
      };
    };
  };
}
