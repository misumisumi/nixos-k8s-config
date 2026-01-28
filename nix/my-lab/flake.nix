{
  description = "Terraform nix environment";
  nixConfig = {
    extra-substituters = [
      "https://misumisumi.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "misumisumi.cachix.org-1:f+5BKpIhAG+00yTSoyG/ihgCibcPuJrfQL3M9qw1REY="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];
  };

  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nur.url = "github:nix-community/NUR";
    flakes.url = "github:misumisumi/flakes";

    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    colmena = {
      url = "github:zhaofengli/colmena/v0.4.0";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        stable.follows = "nixpkgs";
      };
    };
    microvm = {
      url = "github:elsbrock/microvm.nix/feature/machined-registration";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
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
        # Cluster settings managing colmena
        # colmena = import ./nixos/hive.nix {
        #   inherit (inputs.nixpkgs) lib;
        #   inherit inputs self;
        # };
        # colmenaHive = inputs.colmena.lib.makeHive self.colmena;
        nixosModules = import ./modules;
        nixosConfigurations =
          (import ./baremetals {
            inherit (inputs.nixpkgs) lib;
            inherit inputs self;
          })
          // (import ./guests {
            inherit (inputs.nixpkgs) lib;
            inherit inputs self;
          });
        # diskoConfigurations = import ./donfigs/disk-config.nix {
        #   inherit (inputs.nixpkgs) lib;
        # };
      };
    };
}
