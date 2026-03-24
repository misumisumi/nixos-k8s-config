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
      "${static.initial.ip}" = [ "${hostname}.initial.home" ];
      "${static.manage.ip}" = [ "${hostname}.manage.home" ];
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

              iifname "eth1" oifname "eth1.${static.manage.vlanId}" drop
              iifname "eth1.${static.manage.vlanId}" oifname "eth1" drop

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
      netdevs = {
        "eth1.${static.manage.vlanId}" = {
          netdevConfig = {
            Kind = "vlan";
            Name = "eth1.${static.manage.vlanId}";
          };
          vlanConfig = {
            Id = toInt static.manage.vlanId;
          };
        };
      };
      networks = {
        "20-initial" = {
          name = "eth1";
          vlan = [
            "eth1.${static.manage.vlanId}"
          ];
          address = [ "${static.initial.ip}${static.initial.prefix}" ];
        };
        "20-manage" = {
          name = "eth1.${static.manage.vlanId}";
          address = [
            "${static.manage.ip}${static.manage.prefix}"
          ];
        };
      };
    };
  };
}
