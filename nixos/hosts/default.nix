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
    , vmTest ? false
    , wm ? "none"
    , useNixOSWallpaper ? false
    }:
      with lib;
      nixosSystem {
        inherit system;
        specialArgs = { inherit hostname inputs user stateVersion vmTest; }; # specialArgs give some args to modules
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
  ctrl = systemSetting {
    inherit user;
    hostname = "yui";
    system = "x86_64-linux";
    rootDir = ./ctrl;
    scheme = "minimal";
  };
  ctrl-test = systemSetting {
    inherit user;
    hostname = "yui";
    system = "x86_64-linux";
    rootDir = ./ctrl;
    scheme = "minimal";
    vmTest = true;
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
