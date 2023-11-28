{
  description = "Each my machine NixOS System Flake Configuration";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    flakes. url = "github:misumisumi/flakes";
    lxd-nixos.url = "git+https://codeberg.org/adamcstephens/lxd-nixos";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nur.url = "github:nix-community/NUR";
    nvfetcher.url = "github:berberman/nvfetcher";
    nvimdots.url = "github:misumisumi/nvimdots/my-config";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
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
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };
    dotfiles = {
      url = "github:misumisumi/home-manager-config";
      # url = "path:/home/sumi/Templates/nix/nixos-common-config";
      inputs = {
        flakes.follows = "flakes";
        home-manager.follows = "home-manager";
        nixgl.follows = "nixgl";
        nixpkgs-stable.follows = "nixpkgs";
        nixpkgs.follows = "nixpkgs-unstable";
        nur.follows = "nur";
        nvimdots.follows = "nvimdots";
        sops-nix.follows = "sops-nix";
      };
    };
  };

  outputs =
    inputs @ { self
    , flake-parts
    , nixpkgs
    , nixpkgs-unstable
    , flakes
    , ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [
        inputs.lxd-nixos.flakeModules.images
      ];
      lxd.generateImporters = true;
      flake =
        let

          stateVersion = "23.05"; # For Home Manager

          overlay =
            { system }:
            let
              nixpkgs-unstable = import inputs.nixpkgs-unstable {
                inherit system;
                config = { allowUnfree = true; };
              };
            in
            {
              nixpkgs.overlays = [
                flakes.overlays.default
              ]
              ++ (import ./patches { inherit nixpkgs-unstable; });
            };
        in
        {
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
          colmena = (
            import ./instances/hive.nix {
              inherit (self) nixosConfigurations;
              inherit inputs overlay stateVersion;
            }
          );
          nixosConfigurations = (
            import ./lxd {
              inherit (inputs.nixpkgs) lib;
              inherit inputs stateVersion;
            }
          )
          // (
            import ./machines {
              inherit (inputs.nixpkgs) lib;
              inherit inputs overlay stateVersion;
            }
          );
        };
      perSystem =
        { system
        , pkgs
        , ...
        }:
        let
          inherit (import ./lib.nix) mkApp;
          myTerraform = pkgs.terraform.withPlugins (tp: with tp; [ lxd random time ]);
          myScripts = pkgs.callPackage (import ./scripts) { };
          _pkgs = with pkgs;
            with myScripts; [
              bashInteractive
              # software for deployment
              age
              btrfs-progs
              colmena
              dig
              graphviz
              hcl2json
              inetutils
              jq
              libxslt
              hdparm
              myTerraform
              nvfetcher
              sops
              squashfsTools
              tcpdump
              terraform-docs

              # software for managing cluster
              argocd
              etcd
              kubectl
              kubernetes-helm

              # scripts
              check_k8s
              copy_img2lxd
              deploy
              he
              init_lxd
              init_nfs_instance
              add_remote_lxd
              k
              mkage4mgr
              mkage4instance
              mkenv
              mkimg4lxc
              mksshhostkeys
              ter
            ];
          nixpkgs-unstable = import inputs.nixpkgs-unstable {
            system = "x86_64-linux";
            config = { allowUnfree = true; };
          };
        in
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ inputs.nvfetcher.overlays.default ]
              ++ (import ./patches { inherit nixpkgs-unstable; });
            config.allowUnfree = true;
          };
          packages = {
            rescueIpxeScript = self.nixosConfigurations.rescue.config.system.build.netbootIpxeScript;
          };
          apps = with myScripts; {
            mkcerts4dev = mkApp { drv = pkgs.callPackage (import ./certs) { ws = "development"; }; };
            mkcerts4prod = mkApp { drv = pkgs.callPackage (import ./certs) { ws = "production"; }; };
            ter = mkApp { drv = ter; };
            k = mkApp { drv = k; };
            mkimg4lxc = mkApp { drv = mkimg4lxc; };
            deploy = mkApp { drv = deploy; };
          };
          devShells.default = pkgs.mkShell {
            nativeBuildInputs = _pkgs;
            buildInputs = [ ];
            shellHooks = ''
          '';
          };
        };
    };
}



