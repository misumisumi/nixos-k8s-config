{
  lib,
  hostname,
  static,
  ...
}:
let
  inherit (lib) toInt;
in
{
  networking = {
    hostName = hostname;
    hosts = {
      "127.0.0.2" = lib.mkForce [ ];
      "192.168.2.36" = [ hostname ];
    };
    useNetworkd = true;
    firewall = {
      enable = true;
      filterForward = true;
    };
    nftables = {
      enable = true;
      tables = {
        "my-rule" = {
          family = "inet";
          content = ''
            ct helper tftp {
              type "tftp" protocol udp
            }

            chain rpfilter {
              type filter hook prerouting priority filter - 20;

              iifname "eth0" oifname "eth0.${static.kexec.vlanId}" drop
              iifname "eth0.${static.kexec.vlanId}" oifname "eth0" drop

              udp dport 69 ct helper set "tftp"
            }

            chain input {
              # Allow TFTP
              ct helper set "tftp" accept
            }

            chain forward {
              # Don't access manage segment to the outside
              iifname "eth0" oifname "eth0" drop
            }
          '';
        };
      };
    };
  };
  services.resolved.enable = false;
  systemd = {
    network = {
      enable = true;
      netdevs = {
        "eth0.${static.kexec.vlanId}" = {
          netdevConfig = {
            Kind = "vlan";
            Name = "eth0.${static.kexec.vlanId}";
          };
          vlanConfig = {
            Id = toInt static.kexec.vlanId;
          };
        };
      };
      networks = {
        "20-pxe" = {
          name = "eth0";
          vlan = [
            "eth0.${static.kexec.vlanId}"
          ];
          address = [ "${static.pxe.ip}${static.pxe.prefix}" ];
        };
        "20-kexec" = {
          name = "eth0.${static.kexec.vlanId}";
          address = [
            "${static.kexec.ip}${static.kexec.prefix}"
          ];
        };
      };
    };
  };
}
