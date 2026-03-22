{
  lib,
  hostname,
  static,
  ...
}:
{
  networking = {
    hostName = hostname;
    hosts = {
      "192.168.2.40" = [ hostname ];
      "192.168.20.40" = [ hostname ];
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

              iifname "eth1" oifname "eth1.${static.kexec.vlanId}" drop
              iifname "eth1.${static.kexec.vlanId}" oifname "eth1" drop

              udp dport 69 ct helper set "tftp"
            }

            chain input {
              # Allow TFTP
              ct helper set "tftp" accept
            }

            chain forward {
              # Don't access manage segment to the outside
              iifname "eth1" oifname "eth1" drop
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
      netdevs =
        let
          inherit (lib) toInt;
        in
        {
          "eth1.${static.kexec.vlanId}" = {
            netdevConfig = {
              Kind = "vlan";
              Name = "eth1.${static.kexec.vlanId}";
            };
            vlanConfig = {
              Id = toInt static.kexec.vlanId;
            };
          };
        };
      networks = {
        "5-eth0" = {
          name = "eth0";
          address = [ "${static.wan.ip}${static.wan.prefix}" ];
        };
        "10-eth1" = {
          name = "eth1";
          vlan = [ "eth1.${static.kexec.vlanId}" ];
          address = [ "${static.pxe.ip}${static.pxe.prefix}" ];
        };
        "10-eth1.${static.kexec.vlanId}" = {
          name = "eth1.${static.kexec.vlanId}";
          address = [ "${static.kexec.ip}${static.kexec.prefix}" ];
        };
      };
    };
  };
}
