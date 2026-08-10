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
    ../../share/kubelet
    ../../share/settings
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
