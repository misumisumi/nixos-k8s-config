{
  description = "Kubernetes resource configurations";
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

    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixidy = {
      # url = "github:arnarg/nixidy";
      url = "path:/home/sumi/Workspace/nix/server/nixidy";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixhelm = {
      url = "github:farcaller/nixhelm";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      flake-parts,
      nixidy,
      nixhelm,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [
        inputs.devshell.flakeModule
      ];
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
            overlays = [ ];
            config.allowUnfree = true;
          };

          # Make nixidy CLI available
          packages = {
            nixidy-dev = pkgs.writeShellScriptBin "nixidy.dev" ''
              export KUBECONFIG=${./env/dev/kubeconfig}
              ${nixidy.packages.${system}.default}/bin/nixidy $@
            '';
            nixidy-prod = pkgs.writeShellScriptBin "nixidy.prod" ''
              export KUBECONFIG=${./env/prod/kubeconfig}
              ${nixidy.packages.${system}.default}/bin/nixidy $@
            '';
          };
          legacyPackages = {
            nixidyEnvs.${system} = nixidy.lib.mkEnvs {
              inherit pkgs;
              charts = nixhelm.chartsDerivations.${system};

              modules = [ ./modules ];
              envs = {
                dev.modules = [ ./env/dev ];
              };
            };
          };

          # Development shell with nixidy
          devshells.default = {
            packages = [
              self.packages.nixidy-dev
              self.packages.nixidy-prod
            ];
          };
        };
    };
}
