{
  lib,
  self,
  modulesPath,
  ...
}:
let
  inherit (lib) mkForce;
in
{
  imports = [
    ./cockpit.nix
    ../../../share/settings/nix
    ../../../share/settings/locale
    # ../../share/settings/ssh
  ];
  image.modules = mkForce {
    lxc = self.nixosModules.lxc-container;
    lxc-metadata = modulesPath + "/virtualisation/lxc-image-metadata.nix";
  };
}
