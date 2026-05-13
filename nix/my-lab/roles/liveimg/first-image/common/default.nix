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
    self.nixosModules.ipxe
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
}
