{
  lib,
  group,
  hostname,
  static,
  ...
}:
let
  inherit (lib)
    listToAttrs
    nameValuePair
    range
    ;
  ifaces = static.${group}.${hostname}.networks;
  bgp = static.${group}.${hostname}.bgp;
  inherit (bgp) routerId;
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
      "10-wan" = {
        name = ifaces.wan.IF;
        networkConfig = {
          Description = "WAN";
        };
      };
      "10-manage" = {
        name = ifaces.manage.IF;
        networkConfig = {
          Description = "Management network";
        };
        address = [ ifaces.manage.address ];
      };
      "10-intra10G" = {
        name = ifaces.intra10G.IF;
        networkConfig = {
          Description = "Internal 10G network";
        };
      };
    }
    // listToAttrs (
      map (
        n:
        nameValuePair "15-intra40G_${toString n}" {
          name = ifaces."intra40G_${toString n}".IF;
          networkConfig = {
            Description = "IB switch interface";
          };
        }
      ) (range 1 4)
    );
  };
}
