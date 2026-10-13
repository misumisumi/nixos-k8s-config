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
  };
  networking.vxlan.tenants = {
    "home" = {
      name = "home";
      L3VNI = {
        hwAddr = "3F:E9:45:18:AD:4E";
        vni = 11001;
        vlan = 1101;
        local = routerId;
        destinationPort = 4789;
      };
      vniVlanPairs = [
        {
          vni = 11010;
          vlan = 10;
          address = "192.168.10.${idSuffix}/24";
          anycastGateway = {
            hwAddr = "03:03:aa:aa:${hwAddrPart 10}";
            address = "192.168.10.254/24";
          };
        }
      ];
    };
    "iot" = {
      name = "iot";
      L3VNI = {
        hwAddr = "3F:E9:45:18:AD:4F";
        vni = 11002;
        vlan = 1102;
        local = routerId;
        destinationPort = 4789;
      };
      vniVlanPairs = [
        {
          vni = 11020;
          vlan = 20;
          address = "192.168.20.${idSuffix}/24";
          anycastGateway = {
            hwAddr = "03:03:aa:aa:${hwAddrPart 20}";
            address = "192.168.20.254/24";
          };
        }
      ];
    };
    "gst" = {
      name = "gst";
      L3VNI = {
        hwAddr = "3F:E9:45:18:AD:50";
        vni = 11003;
        vlan = 1103;
        local = routerId;
        destinationPort = 4789;
      };
      vniVlanPairs = [
        {
          vni = 11100;
          vlan = 100;
          address = "192.168.100.${idSuffix}/24";
          anycastGateway = {
            hwAddr = "03:03:aa:aa:${hwAddrPart 100}";
            address = "192.168.100.254/24";
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
      # BGP unnumbered の underlay リンク (ホスト側 br_home2host)
      "15-enp0s3" = {
        name = "enp0s3";
        networkConfig = {
          Description = "To host interface";
          # fabric 側の RA を無視する
          IPv6AcceptRA = false;
        };
      };
    };
  };
}
