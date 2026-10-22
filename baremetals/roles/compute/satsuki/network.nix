{
  group,
  hostname,
  static,
  ...
}:
let
  inherit (static.${group}.${hostname}) networks;
  inherit (static.${group}.${hostname}.bgp) routerId;
in
{
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
        routes = [
          {
            Destination = "10.10.10.0/24";
          }
        ];
      };
      "10-manage" = {
        name = networks.manage.IF;
        networkConfig = {
          Description = "Management network";
        };
        address = [ networks.manage.address ];
      };
      "15-intra10G" = {
        name = networks.intra10G.IF;
        networkConfig = {
          Description = "10G network";
          # fabric 側の RA を無視する
          IPv6AcceptRA = false;
        };
      };
      "15-intra40G" = {
        name = networks.intra40G.IF;
        networkConfig = {
          Description = "40G network";
          # fabric 側の RA を無視する
          IPv6AcceptRA = false;
        };
      };
    };
  };
}
