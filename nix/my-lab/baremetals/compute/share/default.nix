{
  modulesPath,
  self,
  lib,
  ...
}:
let
  inherit (lib) mkForce;
in
{
  imports = [
    self.nixosModules.vlan-aware-vxlan
    ../../share/apps/bash.nix
    ../../share/apps/pkgs.nix
    ../../share/settings/console.nix
    ../../share/settings/locale.nix
    ../../share/settings/network.nix
    ../../share/settings/security.nix
    ../../share/settings/ssh.nix
    ../../share/settings/system.nix
  ];
  image.modules = mkForce {
    inherit (self.nixosModules) kexec;
    incus-vm = self + "/modules/incus-virtual-machine.nix";
    lxc-metadata = modulesPath + "/virtualisation/lxc-image-metadata.nix";
  };
}
