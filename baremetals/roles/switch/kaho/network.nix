{
  lib,
  group,
  hostname,
  static,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    listToAttrs
    nameValuePair
    range
    splitString
    sublist
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
        linkConfig = {
          MTUBytes = ifaces.wan.mtu;
        };
        networkConfig = {
          Description = "WAN";
        };
      };
      "10-manage" = {
        name = ifaces.manage.IF;
        linkConfig = {
          MTUBytes = ifaces.manage.mtu;
        };
        networkConfig = {
          Description = "Management network";
        };
        address = [ ifaces.manage.address ];
        routes = ifaces.manage.routes or [ ];
      };
      "10-intra10G" = {
        name = ifaces.intra10G_1.IF;
        linkConfig = {
          MTUBytes = ifaces.intra10G_1.mtu;
        };
        networkConfig = {
          Description = "Internal 10G network";
        };
      };
      # 40G access ポート (home-leaf の macvtap passthru の下位デバイス)。
      # BGP unnumbered のピアではないため 15- ではなく 10- を使う。
      "10-intra40G_4" = {
        name = ifaces.intra40G_4.IF;
        linkConfig = {
          MTUBytes = ifaces.intra40G_4.mtu;
        };
      };
    }
    // listToAttrs (
      map (
        n:
        nameValuePair "15-intra40G_${toString n}" {
          name = ifaces."intra40G_${toString n}".IF;
          linkConfig = {
            MTUBytes = ifaces."intra40G_${toString n}".mtu;
          };
          networkConfig = {
            Description = "IB switch interface";
          };
        }
      ) (range 1 3)
    );
  };
}
