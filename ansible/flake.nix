{
  description = "Playbooks for apps of my homelab";
  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nvfetcher.url = "github:berberman/nvfetcher";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devshell.flakeModule
      ];
      systems = [ "x86_64-linux" ];
      flake = rec {
        overlay = overlays.default; # deprecated attributes for retro compatibility
        overlays.default = final: prev: {
          pythonPackagesOverlays = (prev.pythonPackagesOverlays or [ ]) ++ [
            (pfinal: pprev: {
              ansible-core = pprev.ansible-core.overridePythonAttrs (old: {
                buildInputs = (old.buildInputs or [ ]) ++ [ pprev.kubernetes ];
                makeWrapperArgs =
                  let
                    extra = prev.callPackage ./collections { ansible = pprev.ansible-core; };
                  in
                  old.makeWrapperArgs or [ ]
                  ++ [
                    "--set PYTHONPATH $PYTHONPATH"
                    "--set ANSIBLE_COLLECTIONS_PATH ${extra.collections}"
                    "--set ANSIBLE_ROLES_PATH ${extra.roles}"
                  ];
              });
            })
          ];
          python3 =
            let
              self = prev.python3.override {
                inherit self;
                packageOverrides = prev.lib.composeManyExtensions final.pythonPackagesOverlays;
              };
            in
            self;
          python3Packages = final.python3.pkgs;
        };
      };
    };
}
