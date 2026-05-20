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

    openwrt-imagebuilder = {
      url = "github:astro/nix-openwrt-imagebuilder";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nixos-linstor = {
      url = "git+ssh://git@github.com/misumisumi/nixos-linstor.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    inputs@{
      self,
      flake-parts,
      openwrt-imagebuilder,
      ...
    }:
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
          import ./patches {
            inherit nixpkgs-unstable;
          };
        nixosModules = import ./modules;
        nixosConfigurations = import ./roles {
          inherit (inputs.nixpkgs) lib;
          inherit inputs self;
        };
      };
      perSystem =
        {
          pkgs,
          system,
          ...
        }:
        let
          nixpkgs-unstable = import inputs.nixpkgs-unstable {
            inherit system;
            config = {
              allowUnfree = true;
            };
          };
        in
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              inputs.nixos-linstor.overlays.default
            ];
            config.allowUnfree = true;
          };
          packages =
            let
              mylab-sks8300-8x = import ./roles/switch/sks8300-8x/image.nix {
                pkgs = nixpkgs-unstable;
                inherit openwrt-imagebuilder;
              };
            in
            {
              inherit (mylab-sks8300-8x) prod_switch_sks8300-8x dev_switch_sks8300-8x;
              inherit (pkgs) linkage linkage-gateway;
            };
        };
    };
}
