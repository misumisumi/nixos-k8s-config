{
  static,
  group,
  hostname,
  ...
}:
let
  inherit (static.${group}.${hostname}) manageIP manageIPPrefix;
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
      };
    };
  };
}
