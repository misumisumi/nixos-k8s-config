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
    ../../../share/modules/static.nix
    ../../../share/settings/console.nix
    ../../../share/settings/locale.nix
    ../../../share/settings/system.nix
    ../../../share/settings/security.nix
    ../../../share/settings/users.nix
    ./network.nix
    ./second-stage-boot.nix
    ./ssh.nix
  ];
  hardware.cpu = {
    intel.updateMicrocode = true;
    amd.updateMicrocode = true;
  };
  image.modules = mkForce {
    inherit (self.nixosModules) ipxe;
    lxc = self.nixosModules.lxc-container;
    lxc-metadata = modulesPath + "/virtualisation/lxc-image-metadata.nix";
  };
}
