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
    ./kubelet.nix
    ./certs.nix
  ];

  image.modules = mkForce {
    inherit (inputs.homelab-modules.nixosModules) incus-vm;
    lxc-metadata = {
      imports = [
        "${modulesPath}/virtualisation/lxc-image-metadata.nix"
        ./hostname.tpl.nix
      ];
    };
  };
}
