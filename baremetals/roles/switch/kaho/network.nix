{
  lib,
  group,
  hostname,
  static,
  ...
}:
let
  inherit (static.${group}.${hostname}) manageIP manageIPPrefix routerId;
in
{
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.default.rp_filter" = 0;
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv6.conf.default.forwarding" = 1;
  };
  networking = {
    nftables.enable = true;
    firewall.enable = true;
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
          "${routerId}/32"
        ];
      };
      "10-enp5s0" = {
        matchConfig.Name = [
          "enp5s0"
          "enp4s0f0"
        ];
        networkConfig = {
          Description = "WAN";
        };
      };
      "10-enp6s0" = {
        matchConfig.Name = [
          "enp6s0"
          "eno1"
        ];
        networkConfig = {
          Description = "Management network";
        };
        address = [ "${manageIP}/${manageIPPrefix}" ];
      };
      "10-enp7s0" = {
        matchConfig.Name = [
          "enp7s0"
          "enp4s0f1"
        ];
        networkConfig = {
          Description = "Internal 10G network";
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
