{
  static,
  group,
  tag,
  ...
}:
let
  inherit (static.${group}.${tag}) manageIP manageIPPrefix;
in
{
  systemd.network = {
    networks = {
      "10-enp5s0" = {
        name = "enp5s0";
        networkConfig = {
          Description = "Management network";
        };
        address = [ "${manageIP}/${manageIPPrefix}" ];
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
