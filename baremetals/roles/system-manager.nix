{
  self,
  inputs,
  lib,
}:
let
  inherit (builtins) listToAttrs isAttrs;
  inherit (inputs.system-manager.lib) makeSystemConfig;
  inherit (lib)
    filterAttrs
    flatten
    mapAttrsToList
    mergeStatic
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
    makeSystemConfig {
      specialArgs = {
        inherit
          self
          inputs
          lib
          hostname
          group
          user
          isDev
          isNixOSTest
          ;
        modulesPath = inputs.nixpkgs + "/nixos/modules";
      }; # specialArgs give some args to modules
      modules = [
        inputs.sops-nix.nixosModules.sops
        (inputs.pcp + "/build/nix/nixos-module.nix")
        ./share/modules/static.nix
        ./${group}/${tag}
      ];
    };
  group_and_hosts = mergeStatic ./. "static.nix";
  group_and_hosts_dev = mergeStatic ./. "static_dev.nix";
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
      ) (filterAttrs (_: v: isAttrs v && (v.otherDistro or false)) hosts))
    ) static;

in
# listToAttrs (flatten (mapAttrsToList (config_per_variant group_and_hosts) variants))
# // listToAttrs (flatten (mapAttrsToList (config_per_variant group_and_hosts_dev) variants_dev))
{
  prod_gpu-compute_haruna = systemSetting {
    group = "gpu-compute";
    tag = "haruna";
    system = "aarch64-linux";
    hostname = "haruna";
    user = "renako";
  };
}
