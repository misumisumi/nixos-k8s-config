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
    ../../../share/apps/bash
    ../../../share/apps/pkgs
    ../../../share/apps/wireshark
    ../../../share/settings/console
    ../../../share/settings/locale
    ../../../share/settings/nix
    ../../../share/settings/security
    ../../../share/settings/ssh
    ../../../share/settings/user
    ../../share/ssh.nix
    ./network.nix
  ];
  image.modules = mkForce {
    inherit (self.nixosModules) kexec;
    lxc = modulesPath + "/virtualisation/lxc-container.nix";
    lxc-metadata = modulesPath + "/virtualisation/lxc-image-metadata.nix";
  };
}
