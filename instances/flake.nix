{
  #TODO: fix description
  description = "Each my machine NixOS System Flake Configuration";
  nixConfig = {
    extra-substituters = [
      "https://misumisumi.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "misumisumi.cachix.org-1:f+5BKpIhAG+00yTSoyG/ihgCibcPuJrfQL3M9qw1REY="
    ];
  };

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nur.url = "github:nix-community/NUR";
    flakes.url = "github:misumisumi/flakes";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    homelab-modules.url = "path:../modules";
  };

  outputs =
    inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [
        inputs.devshell.flakeModule
      ];
      flake = {
        nixConfig = {
          extra-substituters = [
            "https://nix-community.cachix.org"
            "https://cache.nixos.org/"
          ];
          extra-trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          ];
        };
        overlay = self.overlays.default;
        overlays.default =
          let
            nixpkgs-unstable = import inputs.nixpkgs-unstable {
              system = "x86_64-linux";
              config = {
                allowUnfree = true;
              };
            };
          in
          import ./patches {
            inherit nixpkgs-unstable;
          };
        # Cluster settings managing colmena
        nixosConfigurations =
          (import ./roles {
            inherit (inputs.nixpkgs) lib;
            inherit inputs self;
          })
          // (import ./test {
            inherit (inputs.nixpkgs) lib;
            inherit inputs self;
          });
      };
      perSystem =
        {
          system,
          pkgs,
          ...
        }:
        let
          nixpkgs-unstable = import inputs.nixpkgs-unstable {
            system = "x86_64-linux";
            config = {
              allowUnfree = true;
            };
          };
        in
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              inputs.flakes.overlays.default
              self.overlays.default
            ];
            config.allowUnfree = true;
          };
          packages = {
            genca = pkgs.callPackage ./scripts/genca.nix { };
            genkubeconfig = pkgs.callPackage ./scripts/genkubeconfig.nix { };
          }
          // (pkgs.callPackages ./scripts/default.nix { })
          // (pkgs.callPackages ./scripts/gencerts.nix { });
        };
    };
}
