{
  description = "My HomeLab develop environment configuration";
  nixConfig = {
    extra-substituters = [
      "https://misumisumi.cachix.org"
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
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nur.url = "github:nix-community/NUR";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
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

    flakes.url = "github:misumisumi/flakes";
  };

  outputs =
    inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [
        inputs.devshell.flakeModule
      ];
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
          apps = with myScripts; {
            ter = mkApp { drv = ter; };
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
                myOpentofu
                sops
                terraform
                terraform-docs

                ter
              ];
          };
        };
    };
}
