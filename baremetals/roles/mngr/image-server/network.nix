{
  lib,
  static,
  group,
  hostname,
  ...
}:
let
  inherit (static.${group}.${hostname}) networks;
  manageIP = lib.removeNetmask networks.manage.address;
in
{
  networking = {
    hostName = hostname;
    hosts = {
      "127.0.0.2" = lib.mkForce [ ];
      "${manageIP}" = [ "${hostname}.home" ];
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

              udp dport 69 ct helper set "tftp"
            }

            chain input {
              # Allow TFTP
              ct helper set "tftp" accept
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
      networks = {
        "20-manage" = {
          name = networks.manage.IF;
          address = [ networks.manage.address ];
        };
      };
    };
  };
}
