{
  lib,
  hostname,
  ...
}:
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
              udp dport 69 ct helper set "tftp"
            }

            chain input {
              # Allow TFTP
              ct helper set "tftp" accept
            }

            chain forward {
              # iifname "eth1" oifname "eth0" drop
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
        "10-wan" = {
          name = "eth0";
          DHCP = "yes";
        };
        "10-eth1" = {
          name = "eth1";
          DHCP = "no";
          address = [ "192.168.2.36/24" ]; # XikeStor SKS8300-8X (chinese 10GbE switch) expect this IP for TFTP server
        };
      };
    };
  };
}
