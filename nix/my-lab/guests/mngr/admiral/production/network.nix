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

              iifname "eth2" oifname "eth2.${static.manage.vlanId}" drop
              iifname "eth2.${static.manage.vlanId}" oifname "eth2" drop

              udp dport 69 ct helper set "tftp"
            }

            chain input {
              # Allow TFTP
              ct helper set "tftp" accept
            }

            chain forward {
              # Don't access manage segment to the outside
              iifname "eth2" oifname "eth2" drop
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
          "eth2.${static.manage.vlanId}" = {
            netdevConfig = {
              Kind = "vlan";
              Name = "eth2.${static.manage.vlanId}";
            };
            vlanConfig = {
              Id = toInt static.manage.vlanId;
            };
          };
        };
      networks = {
        "5-eth1" = {
          name = "eth1";
          address = [ "${static.wan.ip}${static.wan.prefix}" ];
          networkConfig = {
            Description = "WAN";
          };
        };
        "10-eth2" = {
          name = "eth2";
          vlan = [ "eth1.${static.manage.vlanId}" ];
          address = [ "${static.initial.ip}${static.initial.prefix}" ];
        };
        "10-eth2.${static.manage.vlanId}" = {
          name = "eth1.${static.manage.vlanId}";
          address = [ "${static.manage.ip}${static.manage.prefix}" ];
        };
      };
    };
  };
}
