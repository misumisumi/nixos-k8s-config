{ tag ? ""
, ...
}:
let
  config = builtins.fromJSON (builtins.readFile ../config.json);
in
{
  inherit (config.hosts.${tag}) cpu_bender hostname ipv4_address mac_address system;
  inherit (config.hosts) tag;
  inherit (config) hosts;
}
