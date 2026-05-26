{
  inputs,
  lib,
  modulesPath,
  ...
}:
let
  inherit (lib) mkForce;
in
{
  imports = [
    ../../share/apps/bash.nix
    ../../share/modules/static.nix
    ../../share/settings/console.nix
    ../../share/settings/locale.nix
    ../../share/settings/security.nix
    ../../share/settings/system.nix
    ../../share/settings/users.nix
    ../share/ssh.nix
    ./hardware-configuration.nix
    ./network.nix
    ./second-stage-boot.nix
    inputs.homelab-modules.nixosModules.ipxe
  ];
  image.modules = mkForce {
    inherit (inputs.homelab-modules.nixosModules) incus-vm;
    lxc-metadata = modulesPath + "/virtualisation/lxc-image-metadata.nix";
  };
}
