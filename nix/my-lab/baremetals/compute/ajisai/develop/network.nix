{ static, lib, ... }:
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
  networking.vxlan.tenants = {
    "tn1" = {
      name = "tn1";
      L3VNI = {
        hwAddr = "12:12:14:e9:4a:13";
        vni = 11001;
        vlan = 1101;
        local = "10.1.254.${static.bgpId}";
        destinationPort = 4789;
      };
      vniVlanPairs = [
        {
          vni = 11010;
          vlan = 10;
          address = "192.168.10.${static.bgpId}/24";
          anycastGateway = {
            hwAddr = "03:03:aa:aa:${hwAddrPart 10}";
            address = "192.168.10.254/24";
          };
        }
        {
          vni = 11020;
          vlan = 20;
          address = "192.168.20.${static.bgpId}/24";
          anycastGateway = {
            hwAddr = "03:03:aa:aa:${hwAddrPart 20}";
            address = "192.168.20.254/24";
          };
        }
      ];
    };
  };
  systemd.network = {
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
          "10.1.254.${static.bgpId}/32"
        ];
      };
      "10-enp5s0" = {
        name = "enp5s0";
        networkConfig = {
          Description = "Management network";
        };
      };
      "15-enp6s0" = {
        name = "enp6s0";
        networkConfig = {
          Description = "10G network";
        };
      };
      "15-enp7s0" = {
        name = "enp7s0";
        networkConfig = {
          Description = "40G network";
        };
      };
    };
  };
}
