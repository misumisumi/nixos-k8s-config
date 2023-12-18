{ inputs
, lib
, stateVersion
, ...
}:
let
  user = "nixos";
  modules = [
    ../apps/ssh
    ../system/console
    ../system/locale
    ../system/nix
    ../system/security
    ../system/user
  ];
in
{
  lxc-container = with lib;
    nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit stateVersion inputs user; };
      inherit modules;
    };
  lxc-virtual-machine = with lib;
    nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit stateVersion inputs user; };
      modules = modules ++ [
        inputs.sops-nix.nixosModules.sops
        ../system/network
      ];
    };
}
