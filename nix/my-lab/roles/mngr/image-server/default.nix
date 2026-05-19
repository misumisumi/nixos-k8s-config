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
    ../../share/apps/bash.nix
    ../../share/settings/system.nix
    ./dnsmasq.nix
    ./network.nix
    ./nginx.nix
    self.nixosModules.build
    self.nixosModules.multiple-dnsmasq
  ];
  image.modules = mkForce {
    lxc = self.nixosModules.lxc-container;
    lxc-metadata = modulesPath + "/virtualisation/lxc-image-metadata.nix";
  };
}
