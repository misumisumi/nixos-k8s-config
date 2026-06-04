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
    ../share/k8s
    ../share/settings
    ./ceph.nix
    ./certs.nix
    ./kubelet.nix
  ];

  image.modules = mkForce {
    inherit (inputs.homelab-modules.nixosModules) incus-vm;
    lxc-metadata = {
      imports = [
        "${modulesPath}/virtualisation/lxc-image-metadata.nix"
        ../share/virtual-machine/hostname.tpl.nix
      ];
    };
  };
}
