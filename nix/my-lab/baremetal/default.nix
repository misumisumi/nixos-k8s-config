{
  self,
  inputs,
  lib,
}:
let
  systemSetting =
    {
      hostname,
      rootDir,
      system,
      group,
      tag,
      user,
      cpu_bender,
    }:
    lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit
          self
          cpu_bender
          hostname
          inputs
          group
          tag
          user
          ;
      }; # specialArgs give some args to modules
      modules = [
        inputs.sops-nix.nixosModules.sops
        inputs.disko.nixosModules.disko
        ../modules
        rootDir # Each machine config
      ];
    };
  hosts =
    let
      inherit (import ../modules/lib/hosts.nix) hostConfigs;
    in
    lib.mapAttrs (tag: config: rec {
      inherit tag;
      inherit (config)
        user
        group
        hostname
        system
        cpu_bender
        ;
      rootDir = ./${group}/${tag};
    }) hostConfigs;
in
(lib.mapAttrs (name: value: (systemSetting value)) hosts)
// ({
  diskless = lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
      inherit
        self
        inputs
        ;
    }; # specialArgs give some args to modules
    modules = [
      inputs.sops-nix.nixosModules.sops
      inputs.disko.nixosModules.disko
      ../modules
      ./diskless/core
    ];
  };
})
