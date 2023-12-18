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
    , isVM ? false
    , wm ? "none"
    , useNixOSWallpaper ? false
    }:
      with lib;
      nixosSystem {
        inherit system;
        specialArgs = { inherit hostname inputs user stateVersion initial isVM; }; # specialArgs give some args to modules
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

  hosts = {
    primary = {
      inherit user;
      hostname = "yui";
      system = "x86_64-linux";
      rootDir = ./primary;
      scheme = "core";
    };
    secondary = {
      inherit user;
      hostname = "strea";
      system = "x86_64-linux";
      rootDir = ./secondary;
      scheme = "core";
    };
    tertiary = {
      inherit user;
      hostname = "alice";
      system = "x86_64-linux";
      rootDir = ./tertiary;
      scheme = "core";
    };
  };
  attrs = {
    "-build" = {
      initial = false;
      isVM = false;
    };
    "-install" = {
      initial = true;
      isVM = false;
    };
    "-test" = {
      initial = true;
      isVM = true;
    };
  };
in
builtins.listToAttrs
  (lib.flatten (
    lib.mapAttrsToList
      (host: value:
        (lib.mapAttrsToList (target: args: { name = host + "${lib.removePrefix "-build" target}"; value = value // args; }) attrs))
      hosts
  ))
  // {
  rescue = systemSetting {
    user = "nixos";
    hostname = "nixos";
    system = "x86_64-linux";
    rootDir = ./rescue;
    scheme = "minimal";
  };
}

