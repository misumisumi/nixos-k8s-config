{ hostname, ... }:
let
  hosts = builtins.fromJSON (builtins.readFile ../config.json);
in
{
  inherit (hosts.physical.${hostname}) cpu_bender label serverIP;
}