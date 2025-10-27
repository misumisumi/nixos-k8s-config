{ lib, ... }:
let
  # inherit (builtins) toString;
  inherit (lib) toInt;
  VFT_TableID = 210;
  VLAN = "210";
in
{
  services = {
    nscd = {
      enable = true;
    };
    frr = {
      ospf6d = {
        enable = true;
      };
      config = ''
        interface bond-en
          ipv6 ospf6 cost 10
          ipv6 ospf6 area 1.1.1.1

        interface bond-ib
          ipv6 ospf6 area 1.1.1.1
          ipv6 ospf6 cost 1       # Prefer ib over en
      '';
    };
  };
  systemd = {
    network = {
      enable = true;
      netdevs = {
        "bond-en" = {
          netdevConfig = {
            Kind = "bond";
            Name = "bond-en";
          };
          bondConfig = {
            Mode = "active-backup";
            MIIMonitorSec = "1s";
            PrimaryReselectPolicy = "always";
            UpDelaySec = "0";
            DownDelaySec = "0";
          };
        };
        "bond-en.${VLAN}" = {
          netdevConfig = {
            Kind = "vlan";
            Name = "bond-en.${toString VLAN}";
          };
          vlanConfig = {
            Id = toInt VLAN;
          };
        };
        "bond-ib" = {
          netdevConfig = {
            Kind = "bond";
            Name = "bond-ib";
          };
          bondConfig = {
            Mode = "active-backup";
            MIIMonitorSec = "1s";
            PrimaryReselectPolicy = "always";
            UpDelaySec = "0";
            DownDelaySec = "0";
          };
        };
        "bond-ib.${VLAN}" = {
          netdevConfig = {
            Kind = "vlan";
            Name = "bond-ib.${VLAN}";
          };
          vlanConfig = {
            Id = toInt VLAN;
          };
        };
        "vrf-mgmt" = {
          netdevConfig = {
            Kind = "vrf";
            Name = "vrf-mgmt";
          };
          vrfConfig = {
            Table = VFT_TableID;
          };
        };
      };
      networks = {
        "10-en" = {
          name = "en*";
          bond = [ "bond-en" ];
        };
        "10-ib" = {
          name = "ib*";
          bond = [ "bond-en" ];
          vlan = [ "bond-ib.${VLAN}" ];
        };
        "20-bond-en" = {
          name = "bond-en";
          vlan = [ "bond-en.${VLAN}" ];
          networkConfig.LinkLocalAddressing = "no";
          linkConfig.RequiredForOnline = "carrier";
        };
        "20-bond-ib" = {
          name = "bond-ib";
          vlan = [ "bond-ib.${VLAN}" ];
          networkConfig.LinkLocalAddressing = "no";
          linkConfig.RequiredForOnline = "carrier";
        };
        "20-bond-en.${VLAN}" = {
          name = "bond-en.${VLAN}";
          vrf = [ "vrf-mgmt" ];
          networkConfig = {
            DHCP = "yes";
            LinkLocalAddressing = "yes"; # Generate a link-local address for ipv4 and ipv6
          };
        };
        "20-bond-ib.${VLAN}" = {
          name = "bond-en.${VLAN}";
          vrf = [ "vrf-mgmt" ];
          networkConfig = {
            DHCP = "yes";
            LinkLocalAddressing = "yes"; # Generate a link-local address for ipv4 and ipv6
          };
        };
      };
    };
  };
}
