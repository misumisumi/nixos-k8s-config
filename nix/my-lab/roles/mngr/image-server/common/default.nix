{
  lib,
  modulesPath,
  self,
  ...
}:
let
  inherit (lib) mkForce;
in
{
  imports = [
    ./dnsmasq.nix
    ./nginx.nix
    ../../../share/apps/bash.nix
    ../../../share/settings/system.nix
    self.nixosModules.build
    self.nixosModules.multiple-dnsmasq
  ];
  image.modules = mkForce {
    lxc = self.nixosModules.lxc-container;
    lxc-metadata = modulesPath + "/virtualisation/lxc-image-metadata.nix";
  };
}
