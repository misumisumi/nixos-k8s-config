{
  description = "Terraform nix environment";
  nixConfig = {
    extra-substituters = [
      "https://misumisumi.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "misumisumi.cachix.org-1:f+5BKpIhAG+00yTSoyG/ihgCibcPuJrfQL3M9qw1REY="
    ];
    connect-timeout = 5;
  };

  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nur.url = "github:nix-community/NUR";
    flakes.url = "github:misumisumi/flakes";

    nixos-linstor.url = "git+ssh://git@github.com/misumisumi/nixos-linstor.git?ref=main";
    pcp = {
      url = "github:performancecopilot/pcp";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        microvm.follows = "microvm";
      };
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    microvm = {
      url = "github:microvm-nix/microvm.nix";
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
          import ./patches { inherit nixpkgs-unstable; };
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
