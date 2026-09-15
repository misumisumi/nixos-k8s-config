{
  self,
  inputs,
  lib,
}:
let
  inherit (inputs.system-manager.lib) makeSystemConfig;
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
          group
          hostname
          inputs
          isDev
          isNixOSTest
          lib
          self
          system
          user
          ;
        modulesPath = inputs.nixpkgs + "/nixos/modules";
      }; # specialArgs give some args to modules
      modules = [
        inputs.sops-nix.nixosModules.sops
        (inputs.pcp + "/build/nix/nixos-module.nix")
        inputs.homelab-modules.nixosModules.systemd-user
        ./share/modules/static.nix
        ./${group}/${tag}
      ];
    };
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
