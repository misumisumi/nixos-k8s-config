{ lib, pkgs, ... }:
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
  };
  networking = {
    hostName = lib.mkForce "";
    hosts = lib.mkForce { };
    useDHCP = false;
    firewall.enable = false;
  };
  system.activationScripts.mkRandomHostName.text = ''
    echo "Create hostname"
    ${pkgs.diceware}/bin/diceware -n 2 --no-caps -d - > /etc/hostname
  '';
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
          networkConfig.LinkLocalAddressing = "no";
          linkConfig.RequiredForOnline = "carrier";
        };
        "10-ib" = {
          name = "ib*";
          bond = [ "bond-en" ];
          networkConfig.LinkLocalAddressing = "no";
          linkConfig.RequiredForOnline = "carrier";
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
          # vrf = [ "vrf-mgmt" ];
          networkConfig = {
            DHCP = "yes";
            # LinkLocalAddressing = "yes"; # Generate a link-local address for ipv4 and ipv6
          };
        };
        "20-bond-ib.${VLAN}" = {
          name = "bond-en.${VLAN}";
          # vrf = [ "vrf-mgmt" ];
          networkConfig = {
            DHCP = "yes";
            # LinkLocalAddressing = "yes"; # Generate a link-local address for ipv4 and ipv6
          };
        };
      };
    };
  };
}
