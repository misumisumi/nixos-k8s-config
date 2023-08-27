{ inputs
, overlay
, stateVersion
, ...
}:
# Multipul arguments
let
  lib = inputs.nixpkgs.lib;
  settings =
    { hostname
    , system
    , rootDir ? ""
    ,
    }:
    let
      nixpkgs-unstable = import inputs.nixpkgs-unstable {
        inherit system;
        config = { allowUnfree = true; };
      };
    in
    with lib;
    nixosSystem {
      inherit system;
      specialArgs = {
        inherit hostname inputs stateVersion;
        user = hostname;
      }; # specialArgs give some args to modules
      modules = [
        ./hosts/common
        (overlay {
          inherit nixpkgs-unstable;
        })

        (./. + "/${rootDir}") # Each machine conf
      ];
    };
in
{
  lxc-x86_64-container = with lib;
    nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit stateVersion inputs; };
      modules = [
        ./cluster/init/ssh.nix
        ./cluster/init/system.nix
        inputs.lxd-nixos.nixosModules.container
      ];
    };
  lxc-x86_64-virtual-machine = with lib;
    nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit stateVersion inputs; };
      modules = [
        ./cluster/init/ssh.nix
        ./cluster/init/system.nix
        inputs.lxd-nixos.nixosModules.virtual-machine
      ];
    };
}