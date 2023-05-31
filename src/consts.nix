{pkgs, ...}: let
  inherit (pkgs.callPackage ./resources.nix {}) resourcesByType;
  env = (builtins.head (resourcesByType "null_resource")).values.triggers.env;
in {
  virtualIP =
    if (env == "product")
    then "192.168.1.50"
    else "10.150.10.50";
}