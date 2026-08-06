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
    ../../share/k8s
    ../../share/settings
    ./certs.nix
    ./drbd.nix
    ./kubelet.nix
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
