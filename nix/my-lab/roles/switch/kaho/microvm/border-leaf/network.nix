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
  inherit (static.microvm.borderLeaf) routerId;

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
    hostName = "border-leaf";
    useNetworkd = true;
    useDHCP = false;
  };
  networking.vxlan.tenants = {
    "wan" = {
      name = "wan";
      L3VNI = {
        vni = 30001;
        local = routerId;
        destinationPort = 4780;
      };
    };
    "tn1" = {
      name = "tn1";
      L3VNI = {
        hwAddr = "3F:E9:45:18:AD:4B";
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
      "lo${tenants.wan.L3VNI.vni}" = {
        netdevConfig = {
          Name = "lo${tenants.wan.L3VNI.vni}";
          Kind = "dummy";
        };
      };
    };
    networks = {
      "5-lo0" = {
        name = "lo0";
        address = [
          "${tenants.tn1.L3VNI.local}/32"
        ];
      };
      "5-lo${tenants.wan.L3VNI.vni}" = {
        name = "lo${tenants.wan.L3VNI.vni}";
        vrf = [ "${tenants.wan.vrf}" ];
        address = [
          "${tenants.tn1.L3VNI.local}/32"
        ];
      };
      "10-enp0s3" = {
        name = "enp0s3";
        vrf = [ "${tenants.wan.vrf}" ];
        networkConfig = {
          Description = "To Router Interface";
        };
      };
      "15-enp0s4" = {
        name = "enp0s4";
        networkConfig = {
          Description = "40G Interface";
        };
      };
      "15-enp0s5" = {
        name = "enp0s5";
        networkConfig = {
          Description = "10G Interface";
        };
      };
    };
  };
}
