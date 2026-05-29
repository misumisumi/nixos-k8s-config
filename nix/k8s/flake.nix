{
  #TODO: fix description
  description = "Each my machine NixOS System Flake Configuration";
  nixConfig = {
    extra-substituters = [
      "https://misumisumi.cachix.org"
      "https://cuda-maintainers.cachix.org"
    ];
    extra-trusted-public-keys = [
      "misumisumi.cachix.org-1:f+5BKpIhAG+00yTSoyG/ihgCibcPuJrfQL3M9qw1REY="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];
  };

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
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
        # Cluster settings managing colmena
        nixosConfigurations = (
          import ./roles {
            inherit (inputs.nixpkgs) lib;
            inherit inputs self;
          }
        );
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
              (import ./patches { inherit nixpkgs-unstable; })
            ];
            config.allowUnfree = true;
          };
          # apps = with myScripts; {
          #   # mkcerts4dev = mkApp { drv = pkgs.callPackage (import ./scripts/certs) { ws = "eval"; }; };
          #   # mkcerts4prod = mkApp { drv = pkgs.callPackage (import ./scripts/certs) { ws = "production"; }; };
          #   genca = mkApp { drv = pkgs.callPackage ./secrets/production/pki/genca.nix { }; };
          #   gencerts-dev = mkApp {
          #     drv = (pkgs.callPackage ./secrets/production/pki/gencerts.nix { }).develop;
          #   };
          #   k = mkApp { drv = k; };
          #   mkimg4lxc = mkApp { drv = mkimg4lxc; };
          # };
          packages = {
            inherit (pkgs.callPackage ./scripts/gencerts.nix { }) gencerts-dev gencerts-prod gencerts-test;
            inherit (pkgs.callPackage ./scripts/default.nix { })
              k-dev
              k-prod
              k-test
              helm-dev
              helm-prod
              helm-test
              ;
            genca = pkgs.callPackage ./scripts/genca.nix { };
            genkubeconfig = pkgs.callPackage ./scripts/genkubeconfig.nix { };
          };
          # devshells.default = {
          #   commands = [
          #     {
          #       help = "disko";
          #       name = "disko";
          #       command = ''
          #         ${inputs.disko.packages.${system}.disko}/bin/disko ''${@}
          #       '';
          #     }
          #     {
          #       help = "nixos-anywhere";
          #       name = "nixos-anywhere";
          #       command = ''
          #         ${inputs.nixos-anywhere.packages.${system}.nixos-anywhere}/bin/nixos-anywhere ''${@}
          #       '';
          #     }
          #   ];
          #   packages =
          #     with pkgs;
          #     with myScripts;
          #     [
          #       bashInteractive
          #       # software for deployment
          #       age
          #       btrfs-progs
          #       colmena
          #       dig
          #       graphviz
          #       hcl2json
          #       hdparm
          #       inetutils
          #       jq
          #       libxslt
          #       sops
          #       squashfsTools
          #       tcpdump
          #       nixos-generators

          #       # software for managing cluster
          #       argocd
          #       etcd
          #       kubectl

          #       # scripts
          #       # add-remote-incus
          #       # check-k8s
          #       # check-disk-size
          #       # copy-img2incus
          #       # deploy
          #       # init-incus
          #       # init-remote-incus
          #       # k
          #       # mkage4instance
          #       # mkage4mgr
          #       # mkimg4incus
          #       # mksshhostkeys
          #     ];
          # };
        };
    };
}
