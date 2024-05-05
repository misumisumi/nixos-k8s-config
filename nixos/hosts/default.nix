{ inputs
, lib
, stateVersion
}:
let
  systemSetting =
    { hostname
    , rootDir
    , system
    , group
    , tag
    , user
    , cpu_bender
    , homeDirectory ? ""
    , scheme ? "core"
    , wm ? "none"
    , useNixOSWallpaper ? false
    }:
    lib.nixosSystem {
      inherit system;
      specialArgs = { inherit cpu_bender hostname inputs group tag user stateVersion; }; # specialArgs give some args to modules
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
                inherit inputs hostname user homeDirectory scheme useNixOSWallpaper wm;
              };
              sharedModules = [
                inputs.flakes.homeManagerModules.default
                inputs.dotfiles.homeManagerModules.dotfiles
                inputs.sops-nix.homeManagerModules.sops
              ];
              users."${user}" = {
                dotfilesActivation = true;
                home.stateVersion = "23.11";
              };
            };
          }
        ];
    };
  hosts =
    let
      hosts-config = (import ../../utils/hosts.nix { }).hosts;
    in
    lib.mapAttrs
      (tag: config: rec {
        inherit tag;
        inherit (config) user group hostname system cpu_bender;
        rootDir = ./${group}/${tag};
        scheme = "core";
      })
      hosts-config;
in
(lib.mapAttrs (name: value: (systemSetting value)) hosts)
