{ inputs
, lib
, stateVersion
, ...
}:
{
  lxc-container = with lib;
    nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit stateVersion inputs; };
      modules = [
        ../apps/ssh
        ../system/console
        ../system/locale
        ../system/network
        ../system/nix
        ../system/security
        inputs.lxd-nixos.nixosModules.container
      ];
    };
  lxc-virtual-machine = with lib;
    nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit stateVersion inputs; };
      modules = [
        ../apps/ssh
        ../system/console
        ../system/locale
        ../system/network
        ../system/nix
        ../system/security
        inputs.lxd-nixos.nixosModules.virtual-machine
      ];
    };
}
