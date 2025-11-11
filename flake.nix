{
  nixConfig = {
    extra-substituters = [
      "https://misumisumi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "misumisumi.cachix.org-1:f+5BKpIhAG+00yTSoyG/ihgCibcPuJrfQL3M9qw1REY="
    ];
  };
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";
    # develop env tools
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # develop tools
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
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # local modules
    homelab-ansible.url = "path:./ansible";
    homelab-terraform.url = "path:./terraform";
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
          ...
        }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays =
              let
                nixpkgs-unstable = import inputs.nixpkgs-unstable {
                  system = "x86_64-linux";
                  config = {
                    allowUnfree = true;
                  };
                };
              in
              [
                # inputs.flakes.overlays.default
                # (import ./patches { inherit nixpkgs-unstable; })
                inputs.homelab-ansible.overlays.default
                inputs.homelab-terraform.overlays.default
              ];
            config.allowUnfree = true;
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
              {
                help = "nixos-generate";
                name = "nixos-generate";
                command = ''
                  ${inputs.nixos-generators.packages.${system}.nixos-generate}/bin/nixos-generate ''${@}
                '';
              }
            ];
            startup = {
              compinit.text = '''';
            };
            packages = with pkgs; [
              bashInteractive
              ansible
              ter
              tofu-w-plugins

              incus
            ];
          };
        };
    };
}
