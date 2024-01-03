{ inputs
, lib
, stateVersion
, ...
}:
let
  user = "nixos";
in
{
  lxc-container = with lib;
    nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit stateVersion inputs user; };
      modules = [
        ./init/modules.nix
        ./lxd/container
      ];
    };
  lxc-virtual-machine = with lib;
    nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit stateVersion inputs user; };
      modules = [
        ./init/modules.nix
        ./lxd/virtual-machine
      ];
    };
}
