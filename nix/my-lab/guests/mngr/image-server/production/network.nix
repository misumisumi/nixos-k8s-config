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

              iifname "enp5s0" oifname "enp5s0.${static.manage.vlanId}" drop
              iifname "enp5s0.${static.manage.vlanId}" oifname "enp5s0" drop

              udp dport 69 ct helper set "tftp"
            }

            chain input {
              # Allow TFTP
              ct helper set "tftp" accept
            }

            chain forward {
              # Don't access manage segment to the outside
              iifname "enp5s0" oifname "enp5s0" drop
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
        "enp5s0.${static.manage.vlanId}" = {
          netdevConfig = {
            Kind = "vlan";
            Name = "enp5s0.${static.manage.vlanId}";
          };
          vlanConfig = {
            Id = toInt static.manage.vlanId;
          };
        };
      };
      networks = {
        "20-initial" = {
          name = "enp5s0";
          vlan = [
            "enp5s0.${static.manage.vlanId}"
          ];
          address = [ "${static.initial.ip}${static.initial.prefix}" ];
        };
        "20-manage" = {
          name = "enp5s0.${static.manage.vlanId}";
          address = [
            "${static.manage.ip}${static.manage.prefix}"
          ];
        };
      };
    };
  };
}
