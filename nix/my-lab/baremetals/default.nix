{
  self,
  inputs,
  lib,
}:
let
  inherit (builtins) head;
  inherit (lib)
    nameValuePair
    mapAttrs'
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
in
(head (
  mapAttrsToList (
    group: hosts:
    (mapAttrs' (
      tag: value:
      nameValuePair "${group}_${tag}" (systemSetting {
        inherit group tag;
        inherit (value) system hostname user;
      })
    ) hosts)
  ) group_and_hosts
))
// (head (
  mapAttrsToList (
    group: hosts:
    (mapAttrs' (
      tag: value:
      nameValuePair "test_${group}_${tag}" (systemSetting {
        inherit group tag;
        inherit (value) system hostname user;
        isTest = true;
      })
    ) hosts)
  ) group_and_hosts
))
