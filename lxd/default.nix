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
        ./ssh.nix
        ./system.nix
        inputs.lxd-nixos.nixosModules.container
      ];
    };
  lxc-virtual-machine = with lib;
    nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit stateVersion inputs; };
      modules = [
        ./ssh.nix
        ./system.nix
        inputs.lxd-nixos.nixosModules.virtual-machine
      ];
    };
}