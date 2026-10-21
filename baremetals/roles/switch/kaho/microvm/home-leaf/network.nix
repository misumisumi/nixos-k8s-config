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

  idSuffix = last (splitString "." routerId);

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
        hwAddr = "3E:E9:45:18:AD:4E";
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
      # Wi-Fi AP トランク (macvtap) を VLAN ごとに分割するデバイス
      ap-home = {
        netdevConfig = {
          Name = "ap-home";
          Kind = "vlan";
        };
        vlanConfig.Id = 10;
      };
      ap-iot = {
        netdevConfig = {
          Name = "ap-iot";
          Kind = "vlan";
        };
        vlanConfig.Id = 20;
      };
      ap-gst = {
        netdevConfig = {
          Name = "ap-gst";
          Kind = "vlan";
        };
        vlanConfig.Id = 100;
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
      "15-enp0s3" = {
        name = "enp0s3";
        linkConfig = {
          MTUBytes = static.microvm.homeLeaf.mtu;
        };
        networkConfig = {
          Description = "To host interface";
          # fabric 側の RA を無視する
          IPv6AcceptRA = false;
        };
      };
      # Wi-Fi AP トランク (macvtap, MAC でマッチ) から VLAN 10/20/100 を取り出す
      "16-enp0s4" = {
        name = "enp0s4";
        linkConfig = {
          MTUBytes = static.switch.kaho.networks.intra10G_1.mtu;
        };
        networkConfig = {
          Description = "To Wi-Fi AP trunk";
          IPv6AcceptRA = false;
        };
        vlan = [
          "ap-home"
          "ap-iot"
          "ap-gst"
        ];
      };
      # 40G アクセスポート (macvtap, MAC でマッチ) を home VLAN 10 に収容
      "16-home40g" = {
        matchConfig.MACAddress = "20:20:00:00:00:ac";
        linkConfig = {
          MTUBytes = static.switch.kaho.networks.intra40G_4.mtu;
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
      # 各 VLAN を home テナントのブリッジへ untagged(PVID) で収容
      "60-ap-home" = {
        name = "ap-home";
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
      "60-ap-iot" = {
        name = "ap-iot";
        bridge = [
          "home-br"
        ];
        bridgeVLANs = [
          {
            VLAN = 20;
            PVID = 20;
            EgressUntagged = 20;
          }
        ];
      };
      "60-ap-gst" = {
        name = "ap-gst";
        bridge = [
          "home-br"
        ];
        bridgeVLANs = [
          {
            VLAN = 100;
            PVID = 100;
            EgressUntagged = 100;
          }
        ];
      };
    };
  };
}
