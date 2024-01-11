{
  description = "Each my machine NixOS System Flake Configuration";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    flakes. url = "github:misumisumi/flakes";
    lxd-nixos.url = "git+https://codeberg.org/adamcstephens/lxd-nixos";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nur.url = "github:nix-community/NUR";
    nvimdots.url = "github:misumisumi/nvimdots/my-config";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:misumisumi/disko/fix-zpool";
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
      url = "github:nix-community/home-manager/release-23.11";
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
      # url = "path:/home/sumi/Templates/nix/home-manager-config";
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
        inputs.devshell.flakeModule
      ];
      lxd.generateImporters = true;
      flake =
        let
          stateVersion = "23.11"; # For Home Manager
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
          colmena = import ./nixos/hive.nix {
            inherit (inputs.nixpkgs) lib;
            inherit inputs self;
          };
          nixosConfigurations = (
            import ./nixos/instances {
              inherit (inputs.nixpkgs) lib;
              inherit inputs stateVersion;
            }
          )
          // (
            import ./nixos/hosts {
              inherit (inputs.nixpkgs) lib;
              inherit inputs stateVersion;
            }
          );
          diskoConfigurations = import ./nixos/hosts/disk-config.nix {
            inherit (inputs.nixpkgs) lib;
          };
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
          nixpkgs-unstable = import inputs.nixpkgs-unstable {
            system = "x86_64-linux";
            config = { allowUnfree = true; };
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
            rescueIpxeScript = self.nixosConfigurations.rescue.config.system.build.netbootIpxeScript;
          };
          apps = with myScripts; {
            mkcerts4dev = mkApp { drv = pkgs.callPackage (import ./scripts/certs) { ws = "development"; }; };
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
            packages = with pkgs;
              with myScripts; [
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
                myTerraform
                sops
                squashfsTools
                tcpdump
                terraform-docs
                nixos-generators

                # software for managing cluster
                argocd
                etcd
                kubectl
                kubernetes-helm

                # scripts
                add-remote-lxd
                check-k8s
                check-disk-size
                copy-img2lxd
                deploy
                he
                init-lxd
                init-remote-lxd
                k
                mkage4instance
                mkage4mgr
                mkimg4lxc
                mksshhostkeys
                ter
              ];
          };
        };
    };
}



