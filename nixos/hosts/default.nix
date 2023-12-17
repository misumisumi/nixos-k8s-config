{ inputs
, lib
, stateVersion
}:
let
  user = "misumi";
  systemSetting =
    { hostname
    , user
    , system
    , rootDir
    , homeDirectory ? ""
    , scheme ? "minimal"
    , initial ? false
    , wm ? "none"
    , useNixOSWallpaper ? false
    }:
      with lib;
      nixosSystem {
        inherit system;
        specialArgs = { inherit hostname inputs user stateVersion initial; }; # specialArgs give some args to modules
        modules =
          [
            inputs.sops-nix.nixosModules.sops
            inputs.home-manager.nixosModules.home-manager
            inputs.disko.nixosModules.disko
            ../modules
            rootDir # Each machine config
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = {
                  inherit inputs hostname user stateVersion homeDirectory scheme useNixOSWallpaper wm;
                };
                sharedModules = [
                  inputs.flakes.nixosModules.for-hm
                  inputs.nvimdots.nixosModules.nvimdots
                  inputs.dotfiles.homeManagerModules.dotfiles
                  inputs.sops-nix.homeManagerModules.sops
                ];
                users."${user}" = {
                  dotfilesActivation = true;
                };
              };
            }
          ];
      };
in
{
  primary = systemSetting {
    inherit user;
    hostname = "yui";
    system = "x86_64-linux";
    rootDir = ./primary;
    scheme = "core";
    initial = true;
  };
  secondary = systemSetting {
    inherit user;
    hostname = "strea";
    system = "x86_64-linux";
    rootDir = ./secondary;
    scheme = "core";
    initial = true;
  };
  tertiaryary = systemSetting {
    inherit user;
    hostname = "alice";
    system = "x86_64-linux";
    rootDir = ./tertiary;
    scheme = "core";
    initial = true;
  };
  rescue = systemSetting {
    user = "nixos";
    hostname = "nixos";
    system = "x86_64-linux";
    rootDir = ./rescue;
    scheme = "minimal";
  };
}

