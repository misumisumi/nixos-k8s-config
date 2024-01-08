{ hostname, ... }:
let
  hosts = builtins.fromJSON (builtins.readFile ../config.json);
in
{
  inherit (hosts.hosts.${hostname}) cpu_bender ipv4_address;
}
