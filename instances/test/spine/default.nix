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
    ./bgp.nix
    ./network.nix
  ];
  image.modules = mkForce {
    inherit (inputs.homelab-modules.nixosModules) incus-vm;
    lxc-metadata = {
      imports = [
        "${modulesPath}/virtualisation/lxc-image-metadata.nix"
      ];
    };
  };
}
