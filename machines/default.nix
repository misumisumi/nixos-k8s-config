{ inputs
, lib
, overlay
, stateVersion
}:
let
  user = "misumi";
  systemSetting =
    { hostname
    , user
    , system
    , rootDir
    }:
      with lib;
      nixosSystem {
        inherit system;
        specialArgs = { inherit hostname inputs user stateVersion; }; # specialArgs give some args to modules
        modules =
          [
            (overlay {
              inherit system;
            })
            ../modules
            ./common
            rootDir # Each machine config

            inputs.home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit hostname user stateVersion; };
              home-manager.users."${user}" = {
                imports =
                  [
                    ./common/hm.nix
                    inputs.common-config.nixosModules.core
                    inputs.nvimdots.nixosModules.nvimdots
                    inputs.private-config.nixosModules.for-hm
                  ];
              };
            }
          ];
      };
in
{
  ctrl = systemSetting {
    inherit user;
    hostname = "yui";
    system = "x86_64-linux";
    rootDir = ./ctrl;
  };
  worker1 = systemSetting {
    inherit user;
    hostname = "alice";
    system = "x86_64-linux";
    rootDir = ./worker;
  };
  worker2 = systemSetting {
    inherit user;
    hostname = "strea";
    system = "x86_64-linux";
    rootDir = ./worker;
  };
}
