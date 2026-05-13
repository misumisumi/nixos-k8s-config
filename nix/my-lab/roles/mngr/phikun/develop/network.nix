{
  static,
  group,
  hostname,
  ...
}:
let
  inherit (static.${group}.${hostname}) manageIP;
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
          # chain rpfilter {
          #   type filter hook prerouting priority filter - 20;

          #   iifname "enp6s0" oifname "enp6s0.${static.manage.vlanId}" drop
          #   iifname "enp6s0.${static.manage.vlanId}" oifname "enp6s0" drop

          #   udp dport 69 ct helper set "tftp"
          # }
          # chain forward {
          #   # Don't access manage segment to the outside
          #   iifname "enp6s0" oifname "enp6s0" drop
          # }
        };
      };
    };
  };
  systemd = {
    network = {
      enable = true;
      networks = {
        "15-eth0" = {
          name = "eth0";
          address = [ "${manageIP}" ];
        };
      };
    };
  };
}
