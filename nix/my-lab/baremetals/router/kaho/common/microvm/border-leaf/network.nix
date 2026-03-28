{
  lib,
  static,
  ...
}:
let
  inherit (builtins) substring;
  inherit (lib)
    toHexString
    fixedWidthString
    toLower
    ;
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
    hostName = "border-leaf";
    useNetworkd = true;
    useDHCP = false;
    firewall.enable = false;
  };
  networking.vxlan.tenants = {
    "tn1" = {
      name = "tn1";
      L3VNI = {
        hwAddr = "3F:E9:45:18:AD:4B";
        vni = 11001;
        vlan = 1101;
        local = "10.1.254.253";
        destinationPort = 4789;
      };
      vniVlanPairs = [
        {
          vni = 11010;
          vlan = 10;
          address = "192.168.10.253/24";
          anycastGateway = {
            hwAddr = "03:03:aa:aa:${hwAddrPart 10}";
            address = "192.168.10.254/24";
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
          "10.1.254.253/32"
        ];
      };
      "10-enp0s3" = {
        name = "enp0s3";
        networkConfig = {
          Description = "40G Interface";
        };
      };
      "10-enp0s4" = {
        name = "enp0s4";
        networkConfig = {
          Description = "10G Interface";
        };
      };
    };
  };
}
