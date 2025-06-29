{
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
    flakes.url = "github:misumisumi/flakes";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nur.url = "github:nix-community/NUR";
    nixos-images.url = "github:nix-community/nixos-images";
    colmena = {
      url = "github:zhaofengli/colmena/v0.4.0";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        stable.follows = "nixpkgs";
      };
    };
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nixos-anywhere = {
      url = "github:nix-community/nixos-anywhere";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        nixos-stable.follows = "nixpkgs";
        disko.follows = "disko";
      };
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl = {
      url = "github:guibou/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    dotfiles = {
      url = "github:misumisumi/home-manager-config";
      inputs = {
        flakes.follows = "flakes";
        home-manager.follows = "home-manager";
        nixgl.follows = "nixgl";
        nixpkgs-stable.follows = "nixpkgs";
        nixpkgs.follows = "nixpkgs-unstable";
        nur.follows = "nur";
        sops-nix.follows = "sops-nix";
      };
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
        colmena = import ./nixos/hive.nix {
          inherit (inputs.nixpkgs) lib;
          inherit inputs self;
        };
        colmenaHive = inputs.colmena.lib.makeHive self.colmena;
        nixosConfigurations =
          (import ./nixos/instances {
            inherit (inputs.nixpkgs) lib;
            inherit inputs self;
          })
          // (import ./nixos/hosts {
            inherit (inputs.nixpkgs) lib;
            inherit inputs self;
          });
        diskoConfigurations = import ./nixos/hosts/disk-config.nix {
          inherit (inputs.nixpkgs) lib;
        };
      };
      perSystem =
        {
          system,
          pkgs,
          lib,
          ...
        }:
        let
          inherit (import ./lib.nix) mkApp;
          myScripts = pkgs.callPackage (import ./scripts) { };
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
          packages = {
            defaultNetbootIpxeScript = self.nixosConfigurations.netboot.config.system.build.netbootIpxeScript;
            defaultISOImage = self.nixosConfigurations.livecd.config.system.build.isoImage;
          } // inputs.nixos-images.packages.${system};
          apps = with myScripts; {
            mkcerts4dev = mkApp { drv = pkgs.callPackage (import ./scripts/certs) { ws = "eval"; }; };
            mkcerts4prod = mkApp { drv = pkgs.callPackage (import ./scripts/certs) { ws = "production"; }; };
            ter = mkApp { drv = ter; };
            k = mkApp { drv = k; };
            mkimg4lxc = mkApp { drv = mkimg4lxc; };
            deploy = mkApp { drv = deploy; };
          };
          devshells.default = {
            commands = [
              {
                help = "disko";
                name = "disko";
                command = ''
                  ${inputs.disko.packages.${system}.disko}/bin/disko ''${@}
                '';
              }
              {
                help = "nixos-anywhere";
                name = "nixos-anywhere";
                command = ''
                  ${inputs.nixos-anywhere.packages.${system}.nixos-anywhere}/bin/nixos-anywhere ''${@}
                '';
              }
            ];
            packages =
              let
                # HACK https://github.com/NixOS/nixpkgs/issues/283015
                tofuProvider =
                  provider:
                  provider.override (oldArgs: {
                    provider-source-address =
                      lib.replaceStrings
                        [ "https://registry.terraform.io/providers" ]
                        [
                          "registry.opentofu.org"
                        ]
                        oldArgs.homepage;
                  });
                myOpentofu = pkgs.opentofu.withPlugins (
                  tp:
                  with tp;
                  builtins.map tofuProvider [
                    external
                    incus
                    libvirt
                    random
                    sops
                    time
                    tp.null
                  ]
                );
              in
              with pkgs;
              with myScripts;
              [
                bashInteractive
                # software for deployment
                age
                btrfs-progs
                colmena
                dig
                graphviz
                hcl2json
                hdparm
                inetutils
                jq
                libxslt
                myOpentofu
                sops
                squashfsTools
                tcpdump
                terraform
                terraform-docs
                nixos-generators

                # software for managing cluster
                argocd
                etcd
                kubectl
                kubernetes-helm

                # scripts
                add-remote-incus
                check-k8s
                check-disk-size
                copy-img2incus
                deploy
                he
                init-incus
                init-remote-incus
                k
                mkage4instance
                mkage4mgr
                mkimg4incus
                mksshhostkeys
                ter
              ];
          };
        };
    };
}
