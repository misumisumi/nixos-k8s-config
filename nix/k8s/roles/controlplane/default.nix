{
  inputs,
  modulesPath,
  lib,
  ...
}:
let
  inherit (lib) mkForce;
in
{
  imports = [
    ../share/k8s
    ../share/settings
    ./apiserver.nix
    ./certs.nix
    ./controller-manager.nix
    ./kubelet.nix
    ./scheduler.nix
  ];
  image.modules = mkForce {
    lxc = inputs.homelab-modules.nixosModules.lxc-container;
    lxc-metadata = modulesPath + "/virtualisation/lxc-image-metadata.nix";
  };
}
