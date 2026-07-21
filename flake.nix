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
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    flake-root.url = "github:srid/flake-root";
    # develop env tools
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # develop tools
    disko.url = "github:nix-community/disko";
    nixos-anywhere.url = "github:nix-community/nixos-anywhere";
    # local modules
    homelab-baremetals.url = "path:./baremetals";
    homelab-instances.url = "path:./instances";
    homelab-k8s-apps.url = "path:./k8s-apps";
    homelab-terraform.url = "path:./terraform";
  };
  outputs =
    inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [
        inputs.devshell.flakeModule
        inputs.flake-root.flakeModule
      ];
      flake = {
        nixosConfigurations =
          inputs.homelab-baremetals.nixosConfigurations // inputs.homelab-instances.nixosConfigurations;
      };
      perSystem =
        {
          config,
          system,
          lib,
          pkgs,
          ...
        }:
        {
          packages = {
            nixidy = inputs.homelab-k8s-apps.packages.nixidy;
            inherit (inputs.homelab-baremetals.packages.${system}) prod_switch_sks8300-8x dev_switch_sks8300-8x;
          };
          legacyPackages = inputs.homelab-k8s-apps.legacyPackages.${system};
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
            devshell.startup = {
              compinit.text = "";
              flakeRoot.text = ''
                FLAKE_ROOT="''$(${lib.getExe config.flake-root.package})"
                export FLAKE_ROOT
              '';
            };
            packages =
              with pkgs;
              with inputs.homelab-baremetals.packages.${system};
              with inputs.homelab-instances.packages.${system};
              with inputs.homelab-terraform.packages.${system};
              with inputs.homelab-k8s-apps.packages.${system};
              [
                bashInteractive

                ter
                tofu-w-plugins

                mkimg-lxc
                mkimg-incus-vm
                mkimg-kexec
                mkimg-ipxe
                mkimg-list
                mkimg-dev-wrt
                linkage
                linkage-gateway

                genca
                gencerts-prod
                gencerts-dev
                gencerts-test
                genkubeconfig
                k-dev
                v-dev
                helm-dev

                nixidy
              ];
          };
        };
    };
}
