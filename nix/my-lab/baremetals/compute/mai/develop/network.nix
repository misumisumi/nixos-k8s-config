{
  lib,
  group,
  hostname,
  static,
  ...
}:
let
  inherit (builtins) substring;
  inherit (lib)
    last
    toHexString
    fixedWidthString
    toLower
    splitString
    ;
  inherit (static.${group}.${hostname}) address routerId;

  hwAddrPart =
    vid:
    let
      vidToHex = fixedWidthString 4 "0" (toLower (toHexString vid));
    in
    substring 0 2 vidToHex + ":" + substring 2 2 vidToHex;

  idSuffix = last (splitString "." routerId);
in
{
  networking.vxlan.tenants = {
    "tn1" = {
      name = "tn1";
      L3VNI = {
        hwAddr = "08:31:c2:75:7b:e0";
        vni = 11001;
        vlan = 1101;
        local = "${routerId}";
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
          "${routerId}/32"
        ];
        routes = [
          {
            Destination = "10.10.10.0/24";
          }
        ];
      };
      "10-enp5s0" = {
        name = "enp5s0";
        networkConfig = {
          Description = "Management network";
        };
        inherit address;
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
