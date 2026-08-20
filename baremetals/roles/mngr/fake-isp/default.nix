{
  inputs,
  modulesPath,
  lib,
  ...
}:
let
  inherit (lib) mkForce;
in
{
  imports = [
    ../../share/apps/debug.nix
    ../../share/settings/console.nix
    ../../share/settings/locale.nix
    ../../share/settings/system.nix
    ./network.nix
  ];
  image.modules = mkForce {
    lxc = inputs.homelab-modules.nixosModules.lxc-container;
    lxc-metadata = modulesPath + "/virtualisation/lxc-image-metadata.nix";
  };
}
