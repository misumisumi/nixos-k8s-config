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
    ../../../share/apps/bash.nix
    ../../../share/apps/pkgs.nix
    ../../../share/apps/wireshark.nix
    ../../../share/settings/console.nix
    ../../../share/settings/locale.nix
    ../../../share/settings/system.nix
    ../../../share/settings/security.nix
    ../../../share/settings/ssh.nix
    ../../../share/settings/user.nix
    ../../share/ssh.nix
    ./network.nix
  ];
  image.modules = mkForce {
    inherit (self.nixosModules) kexec;
    lxc = modulesPath + "/virtualisation/lxc-container.nix";
    lxc-metadata = modulesPath + "/virtualisation/lxc-image-metadata.nix";
  };
}
