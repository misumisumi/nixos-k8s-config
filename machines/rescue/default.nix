{ inputs
, lib
, overlay
, system
, stateVersion
, user ? "rescue"
, hostname ? "rescue"
}: with lib;
nixosSystem {
  inherit system;
  specialArgs = { inherit inputs hostname user stateVersion; }; # specialArgs give some args to modules
  modules =
    [
      (overlay {
        inherit system;
      })
      ./default-user.nix
      ./imports.nix
      ./netboot.nix
      ./network.nix

      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit hostname user stateVersion; };
        home-manager.users."${user}" = {
          imports =
            [
              ../common/hm.nix
              inputs.common-config.nixosModules.minimal
            ];
        };
      }
    ];
}
