{pkgs, ...}: let
  inherit (pkgs.callPackage ./resources.nix {}) resourcesByType;
  labels = resourcesByType "terraform_data";
  env = (
    if (builtins.length labels) >= 1
    then (builtins.head labels).values.output
    else "develop"
  );
in {
  virtualIP =
    if (env == "product")
    then "192.168.1.50"
    else "10.150.10.50";
}