{
  self,
  inputs,
  lib,
}:
let
  inherit (builtins) listToAttrs isAttrs;
  inherit (lib)
    filterAttrs
    flatten
    importTOML
    mapAttrsToList
    nameValuePair
    pathExists
    ;
  systemSetting =
    {
      group,
      tag,
      system,
      user,
      isDev ? false,
      isNixOSTest ? false,
    }:
    lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit
          self
          inputs
          group
          tag
          user
          isDev
          isNixOSTest
          ;
      }; # specialArgs give some args to modules
      modules = [
        inputs.sops-nix.nixosModules.sops
        inputs.homelab-modules.nixosModules.default
        (if pathExists ./${group}/${tag} then ./${group}/${tag} else ./${tag})
        ({ config, ... }: {
          system.stateVersion = config.system.nixos.release;
        })
      ];
    };
  variants = {
    prod = {
      isDev = false;
      isNixOSTest = false;
    };
  };
  variants_dev = {
    dev = {
      isDev = true;
      isNixOSTest = false;
    };
    test = {
      isDev = true;
      isNixOSTest = true;
    };
  };
in
{
  dev_test_leaf = systemSetting {
    group = "test";
    tag = "leaf";
    system = "x86_64-linux";
    user = "nixos";
  };
  dev_test_spine = systemSetting {
    group = "test";
    tag = "spine";
    system = "x86_64-linux";
    user = "nixos";
  };
}
