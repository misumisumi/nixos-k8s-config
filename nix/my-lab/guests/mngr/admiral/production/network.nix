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

              iifname "enp6s0" oifname "enp6s0.${static.manage.vlanId}" drop
              iifname "enp6s0.${static.manage.vlanId}" oifname "enp6s0" drop

              udp dport 69 ct helper set "tftp"
            }

            chain input {
              # Allow TFTP
              ct helper set "tftp" accept
            }

            chain forward {
              # Don't access manage segment to the outside
              iifname "enp6s0" oifname "enp6s0" drop
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
          "enp6s0.${static.manage.vlanId}" = {
            netdevConfig = {
              Kind = "vlan";
              Name = "enp6s0.${static.manage.vlanId}";
            };
            vlanConfig = {
              Id = toInt static.manage.vlanId;
            };
          };
        };
      networks = {
        "5-enp5s0" = {
          name = "enp5s0";
          address = [ "${static.wan.ip}${static.wan.prefix}" ];
          networkConfig = {
            Description = "WAN";
          };
        };
        "10-enp6s0" = {
          name = "enp6s0";
          vlan = [ "enp6s0.${static.manage.vlanId}" ];
          address = [ "${static.initial.ip}${static.initial.prefix}" ];
        };
        "10-enp6s0.${static.manage.vlanId}" = {
          name = "enp6s0.${static.manage.vlanId}";
          address = [ "${static.manage.ip}${static.manage.prefix}" ];
        };
      };
    };
  };
}
