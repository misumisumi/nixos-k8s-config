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
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
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
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [
        inputs.devshell.flakeModule
      ];
      flake = rec {
        overlay = overlays.default;
        overlays.default =
          final: prev:
          let
            myScripts = prev.callPackage (import ./scripts) { };
          in
          {
            inherit (myScripts) ter;
            tofu-w-plugins = prev.opentofu.withPlugins (
              tp: with tp; [
                external
                incus
                libvirt
                random
                sops
                time
                tp.null
              ]
            );
          };
      };
    };
}
