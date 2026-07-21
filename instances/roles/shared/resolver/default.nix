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
    ../../share/settings
    ../../share/settings/users.nix
    # ./network.nix
    ./unbound.nix
  ];
  image.modules = mkForce {
    inherit (inputs.homelab-modules.nixosModules) incus-vm;
    lxc-metadata = {
      imports = [
        "${modulesPath}/virtualisation/lxc-image-metadata.nix"
        ../../share/virtual-machine/hostname.tpl.nix
      ];
    };
  };
}
