{ config
, lib
, hostname
, tag
, ...
}:
let
  interfaceName = "enp1s0";
  inherit (import ../../../../utils/hosts.nix { inherit tag; }) ipv4_address mac_address;
in
{
  services = {
    nscd = {
      enable = true;
    };
  };
  boot.initrd.network.udhcpc.extraArgs = [
    "-i"
    "${interfaceName}"
  ];
  networking = {
    hostName = "${hostname}";
    interfaces.${interfaceName}.wakeOnLan.enable = true;
    firewall = {
      enable = true;
      trustedInterfaces = [
        "br0"
      ];
    };
  };

  systemd = {
    network = {
      netdevs = {
        "br0" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "br0";
            MACAddress = "${mac_address}";
          };
        } // lib.optionalAttrs (lib.versionAtLeast "23.05" config.system.stateVersion) {
          bridgeConfig = {
            VLANFiltering = true;
          };
        } // lib.optionalAttrs (lib.versionOlder "23.05" config.system.stateVersion) {
          extraConfig = ''
            [Bridge]
            VLANFiltering = true;
          '';
        };
      };
      networks = {
        "10-wired" = {
          name = interfaceName;
          bridge = [ "br0" ];
        };
        "20-br0" = {
          name = "br0";
          DHCP = "yes";
          bridgeVLANs = [
            {
              bridgeVLANConfig = {
                VLAN = "102-103";
              };
            }
          ];
        };
      };
    };
  };
}
