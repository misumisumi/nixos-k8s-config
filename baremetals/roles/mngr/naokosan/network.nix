{
  static,
  group,
  hostname,
  ...
}:
let
  inherit (static.${group}.${hostname}) networks;
in
{
  services.resolved.enable = false;
  networking = {
    hostName = hostname;
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

            chain input {
              # Allow TFTP
              ct helper set "tftp" accept
            }

          '';
        };
      };
    };
  };
  systemd = {
    network = {
      enable = true;
      networks = {
        "15-manage" = {
          name = networks.manage.IF;
          address = [ networks.manage.address ];
        };
      };
    };
  };
}
