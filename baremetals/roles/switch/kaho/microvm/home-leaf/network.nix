{
  lib,
  static,
  ...
}:
let
  inherit (builtins) substring;
  inherit (lib)
    fixedWidthString
    last
    splitString
    toHexString
    toLower
    ;
  inherit (static.microvm.homeLeaf.bgp) routerId;
  inherit (static.microvm.homeLeaf) networks;

  idSuffix = last (splitString "." routerId);

  l3vniHwAddr = "3E:E9:45:18:AD:4E";

  hwAddrPart =
    vid:
    let
      vidToHex = fixedWidthString 4 "0" (toLower (toHexString vid));
    in
    substring 0 2 vidToHex + ":" + substring 2 2 vidToHex;

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
    hostName = "home-leaf";
    useNetworkd = true;
    useDHCP = false;
    # DNS は svc テナント (svc-leaf) のリゾルバに委譲する。main テーブルには
    # default route が無いが、名前解決は各 VRF 内 (ip vrf exec) から行う。
    nameservers = [ "192.168.254.253" ];
  };
  services.resolved.enable = false;
  networking.vxlan.tenants = {
    # 家庭内ネットワーク。1 つの L3 VNI (11001) に LAN/IoT/Guest を VLAN で集約する。
    "home" = {
      name = "home";
      L3VNI = {
        hwAddr = l3vniHwAddr;
        vni = 11001;
        vlan = 1101;
        local = routerId;
        destinationPort = 4789;
        # svc テナント (L3VNI 10001) へ direct leaf-to-leaf でカプセル化する。
        transitVnis = [
          {
            vni = 10001;
            remoteVteps = [
              static.microvm.svcLeaf.bgp.routerId
              static.microvm.borderRouter.bgp.routerId
            ];
          }
        ];
      };
      vniVlanPairs = [
        {
          vni = 11010;
          vlan = 10;
          address = "192.168.10.${idSuffix}/24";
          anycastGateway = {
            hwAddr = "02:03:aa:aa:${hwAddrPart 10}";
            address = "192.168.10.254/24";
          };
        }
        {
          vni = 11020;
          vlan = 20;
          address = "192.168.20.${idSuffix}/24";
          anycastGateway = {
            hwAddr = "02:03:aa:aa:${hwAddrPart 20}";
            address = "192.168.20.254/24";
          };
        }
        {
          vni = 11100;
          vlan = 100;
          address = "192.168.100.${idSuffix}/24";
          anycastGateway = {
            hwAddr = "02:03:aa:aa:${hwAddrPart 100}";
            address = "192.168.100.254/24";
          };
        }
      ];
      # VLAN 間の L3 分離: VLAN 10 から VLAN 20/100 への通信のみ許可。
      isolation.allowed = [
        {
          from = 10;
          to = [
            20
            100
          ];
        }
      ];
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
    };
    networks = {
      "5-lo0" = {
        name = "lo0";
        address = [
          "${routerId}/32"
        ];
        routes = [
          {
            Destination = "10.10.10.0/24";
          }
        ];
      };
      # BGP unnumbered の underlay リンク (ホスト側 br_home2host)
      "15-host" = {
        name = networks.host.IF;
        linkConfig = {
          MTUBytes = static.microvm.homeLeaf.mtu;
        };
        networkConfig = {
          Description = "To host interface";
          # fabric 側の RA を無視する
          IPv6AcceptRA = false;
        };
      };
      # 下流の managed L2 が VLAN 10/20/100 を trunk で運ぶため、
      # ここではタグを剥がさず tagged のまま home-br に収容する。
      # overlay は 1500 (VXLAN/ブリッジ) なので AP 側に合わせる。
      "16-apTrunk" = {
        name = networks.apTrunk.IF;
        linkConfig = {
          MTUBytes = 1500;
        };
        networkConfig = {
          Description = "To managed L2 (Wi-Fi AP trunk)";
          IPv6AcceptRA = false;
        };
        bridge = [
          "home-br"
        ];
        bridgeVLANs = [
          { VLAN = 10; }
          { VLAN = 20; }
          { VLAN = 100; }
        ];
      };
      # 10G アクセスポート (intra10G_2) を home VLAN 10 に収容
      "16-home10G" = {
        name = networks.intra10G_2.IF;
        linkConfig = {
          MTUBytes = static.microvm.homeLeaf.mtu;
        };
        networkConfig = {
          Description = "To home 10G access port";
          IPv6AcceptRA = false;
        };
        bridge = [
          "home-br"
        ];
        bridgeVLANs = [
          {
            VLAN = 10;
            PVID = 10;
            EgressUntagged = 10;
          }
        ];
      };
      # 40G アクセスポートを home VLAN 10 に収容
      # VF (mlx4) の HW MAC フィルタは 1 MAC しか通さないため、
      # bridge/L3VNI と同じ MAC に固定して local entry で受信させる。
      "16-home40G" = {
        name = networks.intra40G_4.IF;
        linkConfig = {
          MTUBytes = static.microvm.homeLeaf.mtu;
          MACAddress = l3vniHwAddr;
        };
        networkConfig = {
          Description = "To home 40G access port";
          IPv6AcceptRA = false;
        };
        bridge = [
          "home-br"
        ];
        bridgeVLANs = [
          {
            VLAN = 10;
            PVID = 10;
            EgressUntagged = 10;
          }
        ];
      };
    };
  };
}
