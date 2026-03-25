{
  self,
  inputs,
  lib,
}:
let
  inherit (builtins) listToAttrs;
  inherit (lib)
    flatten
    nameValuePair
    mapAttrsToList
    importTOML
    optional
    ;
  systemSetting =
    {
      group,
      tag,
      system,
      hostname,
      user,
      isTest ? false,
    }:
    lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit
          self
          inputs
          hostname
          group
          user
          isTest
          ;
      }; # specialArgs give some args to modules
      modules = [
        inputs.sops-nix.nixosModules.sops
        inputs.disko.nixosModules.disko
        self.nixosModules.default
        ./share/modules/static.nix
        ./${group}/${tag}/common
      ]
      ++ optional isTest ./${group}/${tag}/test
      ++ optional (!isTest) ./${group}/${tag}/production;
    };
  group_and_hosts = importTOML ./static.toml;
  variants = {
    prod = {
      isDev = false;
      isNixOSTest = false;
    };
    dev = {
      isDev = true;
      isNixOSTest = false;
    };
    test = {
      isDev = true;
      isNixOSTest = true;
    };
  };
  config_per_variant =
    n: v:
    mapAttrsToList (
      group: hosts:
      (mapAttrsToList (
        tag: value:
        nameValuePair "${n}_${group}_${tag}" (systemSetting {
          inherit group tag;
          inherit (value) system hostname user;
          inherit (v) isDev isNixOSTest;
        })
      ) hosts)
    ) group_and_hosts;

in
listToAttrs (flatten (mapAttrsToList config_per_variant variants))
