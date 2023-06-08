{
  inputs,
  overlay,
  stateVersion,
  user,
  ...
}:
# Multipul arguments
let
  lib = inputs.nixpkgs.lib;
  settings = {
    hostname,
    user,
    rootDir ? "",
  }: let
    hostConf = ./. + "/${rootDir}" + /home.nix;
    system = "x86_64-linux";
    pkgs-stable = import inputs.nixpkgs-stable {
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
          (overlay {
            inherit (inputs) nixpkgs;
            inherit pkgs-stable;
          })
          inputs.common-config.nixosModules.for-nixos
          # ../modules

          (./. + "/${rootDir}") # Each machine conf

          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit hostname user stateVersion;};
            home-manager.users."${user}" = {
              # Common home conf + Each machine conf
              imports = [
                (import ../hm/hm.nix)
                (import hostConf)
                inputs.flakes.nixosModules.for-hm
                inputs.common-config.nixosModules.for-hm
                inputs.nvimdots.nixosModules.for-hm
              ];
            };
          }
        ];
      };
in {
  yui-host = settings {
    hostname = "yui";
    rootDir = "hosts/yui";
    inherit user;
  };
  lxc-container = with lib;
    nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit stateVersion inputs;};
      modules = [
        ./cluster/init
        inputs.lxd-nixos.nixosModules.container
      ];
    };
  lxc-virtual-machine = with lib;
    nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit stateVersion inputs;};
      modules = [
        ./cluster/init
        inputs.lxd-nixos.nixosModules.virtual-machine
      ];
    };
}