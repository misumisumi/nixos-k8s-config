{
  lib,
  inputs,
  modulesPath,
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
    inputs.homelab-modules.nixosModules.build
    inputs.homelab-modules.nixosModules.multiple-dnsmasq
  ];
  image.modules = mkForce {
    lxc = inputs.homelab-modules.nixosModules.lxc-container;
    lxc-metadata = modulesPath + "/virtualisation/lxc-image-metadata.nix";
  };
}
