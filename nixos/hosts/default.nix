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
    , initial ? false
    , wm ? "none"
    , useNixOSWallpaper ? false
    }:
    lib.nixosSystem {
      inherit system;
      specialArgs = { inherit cpu_bender hostname inputs group tag user stateVersion initial; }; # specialArgs give some args to modules
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
  devnodes = {
    node1 =
      {
        config = {
          group = "devnode";
          hostname = "node1";
        };
      };
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
  attrs = {
    "-install" = {
      initial = true;
    };
  };
in
builtins.listToAttrs
  (lib.flatten (
    lib.mapAttrsToList
      (tag: value:
        (lib.mapAttrsToList
          (postfix: args: {
            name = tag + postfix;
            value = systemSetting (value // args);
          })
          attrs))
      (lib.filterAttrs (tag: _: tag != "netboot" && tag != "livecd") hosts)
  )) //
(lib.mapAttrs (name: value: (systemSetting value)) hosts)
