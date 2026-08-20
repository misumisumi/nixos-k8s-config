{
  static,
  group,
  tag,
  ...
}:
let
  inherit (static.${group}.${tag}.networks.manage) IF address;
in
{
  systemd.network = {
    networks = {
      "10-enp5s0" = {
        name = IF;
        networkConfig = {
          Description = "Management network";
        };
        address = [ address ];
        routes = [
          {
            Destination = "0.0.0.0/0";
            Gateway = "172.16.1.253";
          }
        ];
      };
    };
  };
}
