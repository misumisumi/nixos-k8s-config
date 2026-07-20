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
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";
    flake-root.url = "github:srid/flake-root";
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
    # local modules
    # homelab-ansible.url = "path:./ansible";
    homelab-mylab.url = "path:./nix/my-lab";
    homelab-k8s.url = "path:./nix/k8s";
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
          inputs.homelab-mylab.nixosConfigurations // inputs.homelab-k8s.nixosConfigurations;
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
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              inputs.homelab-k8s.overlays.default
              inputs.homelab-mylab.overlays.default
              inputs.homelab-terraform.overlays.default
            ];
            config.allowUnfree = true;
          };
          packages = {
            inherit (inputs.homelab-mylab.packages.${system}) prod_switch_sks8300-8x dev_switch_sks8300-8x;
          };
          devshells.default =
            let
              nixpkgs-unstable = import inputs.nixpkgs-unstable {
                system = "x86_64-linux";
                config = {
                  allowUnfree = true;
                };
              };
            in
            {
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
                [
                  bashInteractive
                  ansible
                  ter
                  tofu-w-plugins

                  incus
                  openssl
                  python3
                  gawk

                  mkimg-lxc
                  mkimg-incus-vm
                  mkimg-kexec
                  mkimg-ipxe
                  mkimg-list
                  mkimg-dev-wrt

                  genca
                  gencerts-prod
                  gencerts-dev
                  gencerts-test
                  genkubeconfig
                  k-dev
                  v-dev
                  helm-dev
                ]
                ++ (with inputs.homelab-mylab.packages.${system}; [
                  linkage
                  linkage-gateway
                ]);
            };
        };
    };
}
