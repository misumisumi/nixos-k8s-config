{ pkgs, hostname, ... }:
let
  inherit (pkgs.callPackage (../../../utils/hosts.nix) { inherit hostname; }) serverIP;
in
{
  deployment.targetHost = serverIP;
}
