{ inputs
, lib
, stateVersion
}:
let
  user = "misumi";
  systemSetting =
    { hostname
    , rootDir
    , system
    , group
    , tag
    , user
    , homeDirectory ? ""
    , scheme ? "minimal"
    , initial ? false
    , isVM ? false
    , wm ? "none"
    , useNixOSWallpaper ? false
    }:
    lib.nixosSystem {
      inherit system;
      specialArgs = { inherit hostname inputs group tag user stateVersion initial isVM; }; # specialArgs give some args to modules
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

  hosts =
    let
      hosts-config = (import ../../utils/hosts.nix { }).hosts;
    in
    lib.mapAttrs
      (tag: config: rec {
        inherit user tag;
        inherit (config) group hostname system;
        rootDir = ./${group}/${tag};
        scheme = "core";
      })
      hosts-config;
  attrs = {
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
      (tag: value:
        (lib.mapAttrsToList
          (target: args: {
            name = tag + target;
            value = systemSetting (value // args);
          })
          attrs))
      (lib.filterAttrs (tag: _: tag != "rescue") hosts)
  ))//
  (lib.mapAttrs (name: systemSetting) hosts)
