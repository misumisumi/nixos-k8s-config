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
  hwAddrPart =
    vid:
    let
      vidToHex = fixedWidthString 4 "0" (toLower (toHexString vid));
    in
    substring 0 2 vidToHex + ":" + substring 2 2 vidToHex;

  inherit (static.${group}.${hostname}) networks;
  inherit (static.${group}.${hostname}.bgp) routerId;
  idSuffix = last (splitString "." routerId);
in
{
  networking.vxlan.tenants = {
    "tn1" = {
      name = "tn1";
      L3VNI = {
        hwAddr = "07:26:0f:57:dc:fc";
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
      "10-manage" = {
        name = networks.manage.IF;
        networkConfig = {
          Description = "Management network";
        };
        address = [ networks.manage.address ];
      };
      "15-intra10G" = {
        name = networks.intra10G.IF;
        networkConfig = {
          Description = "10G network";
        };
      };
      "15-intra40G" = {
        name = networks.intra40G.IF;
        networkConfig = {
          Description = "40G network";
        };
      };
    };
  };
}
