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
    ../../share/kubelet
    ../../share/settings
    ./apiserver.nix
    ./certs.nix
    ./controller-manager.nix
    ./kubelet.nix
    ./scheduler.nix
  ];
  image.modules = mkForce {
    inherit (inputs.homelab-modules.nixosModules) incus-vm;
    lxc-metadata = {
      imports = [
        "${modulesPath}/virtualisation/lxc-image-metadata.nix"
        ../../share/templates/hostname.tpl.nix
      ];
    };
  };
}
