{
  inputs,
  lib,
  modulesPath,
  ...
}:
let
  inherit (lib) mkForce;
in
{
  imports = [
    ./traefik.nix
    ../share/settings
  ];

  image.modules = mkForce {
    lxc = inputs.homelab-modules.nixosModules.lxc-container;
    lxc-metadata = {
      imports = [
        "${modulesPath}/virtualisation/lxc-image-metadata.nix"
      ];
    };
  };
}
