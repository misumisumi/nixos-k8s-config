{pkgs, ...}: let
  inherit (pkgs.callPackage ./resources.nix {}) resourcesByType;
  labels = resourcesByType "terraform_data";
  config = builtins.fromJSON (builtins.readFile ../config.json);
in rec {
  workspace = (
    if (builtins.length labels) >= 1
    then (builtins.head labels).values.output
    else "develop"
  );
  virtualIP = config.virtualIPs."${workspace}";
}