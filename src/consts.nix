{pkgs, ...}: let
  inherit (pkgs.callPackage ./resources.nix {}) resourcesByType;
  labels = resourcesByType "null_resource";
  env = (
    if (builtins.length labels) >= 1
    then (builtins.head labels).values.triggers.env
    else "develop"
  );
in {
  ts = resourcesByType "null_resource";
  virtualIP =
    if (env == "product")
    then "192.168.1.50"
    else "10.150.10.50";
}