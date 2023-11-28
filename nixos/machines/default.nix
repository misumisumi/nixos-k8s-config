{ inputs
, lib
, overlay
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
    , wm ? "none"
    , useNixOSWallpaper ? false
    }:
      with lib;
      nixosSystem {
        inherit system;
        specialArgs = { inherit hostname inputs user stateVersion; }; # specialArgs give some args to modules
        modules =
          [
            inputs.sops-nix.nixosModules.sops
            ../modules
            rootDir # Each machine config

            inputs.home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = false;
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
  ctrl = systemSetting {
    inherit user;
    hostname = "yui";
    system = "x86_64-linux";
    rootDir = ./ctrl;
    scheme = "minimal";
  };
  # worker1 = systemSetting {
  #   inherit user;
  #   hostname = "alice";
  #   system = "x86_64-linux";
  #   rootDir = ./worker;
  # };
  # worker2 = systemSetting {
  #   inherit user;
  #   hostname = "strea";
  #   system = "x86_64-linux";
  #   rootDir = ./worker;
  # };
  rescue = systemSetting {
    user = "nixos";
    hostname = "nixos";
    system = "x86_64-linux";
    rootDir = ./rescue;
    scheme = "minimal";
  };
}
