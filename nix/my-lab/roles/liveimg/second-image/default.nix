{
  self,
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
    ../../share/apps/debug.nix
    ../../share/apps/pkgs.nix
    ../../share/settings/console.nix
    ../../share/settings/locale.nix
    ../../share/settings/security.nix
    ../../share/settings/ssh.nix
    ../../share/settings/system.nix
    ../../share/settings/users.nix
    ../share/ssh.nix
    ./hardware-configuration.nix
    ./network.nix
  ];
  image.modules = mkForce {
    inherit (self.nixosModules) kexec;
    incus-vm = self + "/modules/incus-virtual-machine.nix";
    lxc-metadata = modulesPath + "/virtualisation/lxc-image-metadata.nix";
  };
}
