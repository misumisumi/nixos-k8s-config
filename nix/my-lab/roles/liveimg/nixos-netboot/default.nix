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
    ../../share/apps/pkgs.nix
    ../../share/settings/console.nix
    ../../share/settings/locale.nix
    ../../share/settings/security.nix
    ../../share/settings/ssh.nix
    ../../share/settings/system.nix
    ../../share/settings/users.nix
    ../share/ssh.nix
    ./network.nix
    inputs.homelab-modules.nixosModules.ipxe
  ];
  image.modules = mkForce {
    incus-vm = "${inputs.homelab-modules.nixosModules}/modules/incus-virtual-machine.nix";
    lxc-metadata = modulesPath + "/virtualisation/lxc-image-metadata.nix";
  };
}
