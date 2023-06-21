{
  description = "Each my machine NixOS System Flake Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    lxd-nixos = {
      url = "git+https://codeberg.org/adamcstephens/lxd-nixos";
      inputs.nixpkgs.follows = "nixpkgs-stable";
      inputs.nixpkgs-2211.follows = "nixpkgs-stable";
      inputs.nixpkgs-unstable.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flakes = {
      url = "github:misumisumi/flakes";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    flake-parts,
    nixpkgs,
    nixpkgs-stable,
    flakes,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];
      imports = [
        inputs.lxd-nixos.flakeModules.images
      ];
      lxd.generateImporters = true;
      flake = let
        stateVersion = "23.05"; # For Home Manager

        overlay = {
          nixpkgs,
          pkgs-stable,
          ...
        }: {
          nixpkgs.overlays = [
            flakes.overlays.default
          ];
          # ++ (import ./patches {inherit pkgs-stable;});
        };
      in
        {
          # Cluster settings managing colmena
          colmena = (
            import ./machines/hive.nix {
              inherit inputs stateVersion;
            }
          );
        }
        // {
          nixosConfigurations = (
            import ./machines {
              inherit inputs overlay stateVersion;
            }
          );
        };
      perSystem = {
        system,
        pkgs,
        ...
      }: let
        inherit (import ./lib.nix) mkApp;
        mkcerts = pkgs.callPackage (import ./certs) {};
        myTerraform = pkgs.terraform.withPlugins (tp: [tp.lxd tp.time]);
        myScripts = pkgs.callPackage (import ./scripts) {};
        _pkgs = with pkgs;
        with myScripts; [
          bashInteractive
          # software for deployment
          colmena
          jq
          libxslt
          btrfs-progs
          terraform-docs
          hcl2json
          graphviz
          myTerraform

          # software for managing cluster
          argocd
          etcd
          kubectl
          kubernetes-helm

          # scripts
          check_k8s
          copy_img2lxd
          deploy
          h-dev
          init_lxd
          add_remote_lxd
          k
          mkbootfs
          mkcerts
          mkenv
          mkimg4lxc
          mkrootfs
          mksshconfig
          mountrootfs
          unmountrootfs
          ter
        ];
      in {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [];
          config.allowUnfree = true;
        };
        apps = with myScripts; {
          mkcerts = mkApp {drv = mkcerts;};
          ter = mkApp {drv = ter;};
          k = mkApp {drv = k;};
          mkimg4lxc = mkApp {drv = mkimg4lxc;};
          deploy = mkApp {drv = deploy;};
        };
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = _pkgs;
          buildInputs = [];
          shellHooks = ''
          '';
        };
      };
    };
}