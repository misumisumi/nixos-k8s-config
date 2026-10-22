{
  lib,
  static,
  config,
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
  inherit (config.networking.vxlan) tenants;
  inherit (static.microvm.svcLeaf.bgp) routerId;

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
    hostName = "svc-leaf";
    useNetworkd = true;
    useDHCP = false;
    # DNS は svc テナントのリゾルバを VRF 内から直接引く。
    nameservers = [ "192.168.254.253" ];
  };
  # systemd-resolved の stub (127.0.0.53) は VRF 内から到達できない。
  services.resolved.enable = false;
  networking.vxlan.tenants = {
    # service テナント。DNS/リゾルバ等の共有サービスを隔離する。
    # ゾーン (home/iot/gst) からは EVPN downstream VNI で到達する。
    "svc" = {
      name = "svc";
      L3VNI = {
        hwAddr = "3E:E9:45:18:AD:51";
        vni = 10001;
        vlan = 1001;
        local = routerId;
        destinationPort = 4789;
        # home テナント (L3VNI 11001) へ direct leaf-to-leaf でカプセル化する。
        transitVnis = [
          {
            vni = 11001;
            remoteVteps = [
              static.microvm.homeLeaf.bgp.routerId
              static.microvm.borderRouter.bgp.routerId
            ];
          }
        ];
      };
      vniVlanPairs = [
        {
          vni = 10010;
          vlan = 1010;
          address = "192.168.254.${idSuffix}/24";
          anycastGateway = {
            hwAddr = "02:03:aa:aa:${hwAddrPart 1010}";
            address = "192.168.254.254/24";
          };
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
      # BGP unnumbered の underlay リンク (ホスト側 br_svc2host)
      "15-host" = {
        name = static.microvm.svcLeaf.networks.host.IF;
        linkConfig = {
          MTUBytes = static.microvm.svcLeaf.mtu;
        };
        networkConfig = {
          Description = "To host interface";
          # fabric 側の RA を無視する
          IPv6AcceptRA = false;
        };
      };
    };
  };
}
