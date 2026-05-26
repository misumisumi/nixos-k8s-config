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
    ;
  systemSetting =
    {
      group,
      tag,
      system,
      hostname,
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
          hostname
          group
          user
          isDev
          isNixOSTest
          ;
      }; # specialArgs give some args to modules
      modules = [
        inputs.sops-nix.nixosModules.sops
        inputs.disko.nixosModules.disko
        inputs.nixos-linstor.nixosModules.linstor
        inputs.nixos-linstor.nixosModules.linkage
        inputs.homelab-modules.nixosModules.default
        (inputs.pcp + "/build/nix/nixos-module.nix")
        ./share/modules/static.nix
        ./${group}/${tag}
      ];
    };
  group_and_hosts = importTOML ./static.toml;
  group_and_hosts_dev = importTOML ./static_dev.toml;
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
  config_per_variant =
    static: n: v:
    mapAttrsToList (
      group: hosts:
      (mapAttrsToList (
        tag: value:
        nameValuePair "${n}_${group}_${tag}" (systemSetting {
          inherit group tag;
          inherit (value) system hostname user;
          inherit (v) isDev isNixOSTest;
        })
      ) (filterAttrs (_: v: isAttrs v && !(v.notShow or false)) hosts))
    ) static;

in
listToAttrs (flatten (mapAttrsToList (config_per_variant group_and_hosts) variants))
// listToAttrs (flatten (mapAttrsToList (config_per_variant group_and_hosts_dev) variants_dev))
