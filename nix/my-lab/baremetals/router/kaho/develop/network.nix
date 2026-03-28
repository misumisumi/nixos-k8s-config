{
  lib,
  hostname,
  ...
}:
{
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.default.rp_filter" = 0;
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv6.conf.default.forwarding" = 1;
  };
  networking = {
    hostName = hostname;
    useNetworkd = true;
    useDHCP = false;
    firewall.enable = false;
  };
  systemd.network = {
    netdevs = {
      lo0 = {
        netdevConfig = {
          Name = "lo0";
          Kind = "dummy";
        };
      };
    };
    networks = {
      "5-lo0" = {
        name = "lo0";
        address = [
          "10.1.254.1/32"
        ];
      };
      "10-enp5s0" = {
        name = "enp5s0";
        networkConfig = {
          Description = "WAN";
        };
      };
      "10-enp6s0" = {
        name = "enp6s0";
        networkConfig = {
          Description = "Management network";
        };
      };
      "10-enp7s0" = {
        name = "enp7s0";
        networkConfig = {
          Description = "10G network";
        };
      };
    }
    // (
      let
        inherit (lib)
          range
          listToAttrs
          nameValuePair
          ;
        interfaces = map (
          x:
          let
            x' = toString x;
          in
          nameValuePair "15-enp${x'}s0" {
            name = "enp${x'}s0";
            networkConfig = {
              Description = "IB switch interface";
            };
          }
        ) (range 8 11);
      in
      listToAttrs interfaces
    );
  };
}
