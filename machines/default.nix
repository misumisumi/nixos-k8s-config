{
  inputs,
  overlay,
  stateVersion,
  user,
  home-manager,
  nixpkgs,
  nixpkgs-stable,
  nur,
  common-config,
  flakes,
  nvimdots,
  ...
}:
# Multipul arguments
let
  lib = nixpkgs.lib;
  settings = {
    hostname,
    user,
    rootDir ? "",
  }: let
    hostConf = ./. + "/${rootDir}" + /home.nix;
    system = "x86_64-linux";
    pkgs-stable = import nixpkgs-stable {
      inherit system;
      config = {allowUnfree = true;};
    };
  in
    with lib;
      nixosSystem {
        inherit system;
        specialArgs = {inherit hostname inputs user stateVersion;}; # specialArgs give some args to modules
        modules = [
          ./configuration.nix # Common system conf
          (overlay {inherit nixpkgs pkgs-stable;})
          nur.nixosModules.nur
          common-config.nixosModules.for-nixos
          # ../modules

          (./. + "/${rootDir}") # Each machine conf

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit hostname user stateVersion;};
            home-manager.users."${user}" = {
              # Common home conf + Each machine conf
              imports = [
                (import ../hm/hm.nix)
                (import hostConf)
                flakes.nixosModules.for-hm
                common-config.nixosModules.for-hm
                nvimdots.nixosModules.for-hm
              ];
            };
          }
        ];
      };
in {
  yui-host = settings {
    hostname = "yui";
    rootDir = "k8s/yui";
    inherit user;
  };
  terraform-lxc = with lib;
    nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit stateVersion;};
      modules = [
        ./terraform/init
      ];
    };
}