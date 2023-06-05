{
  description = "Each my machine NixOS System Flake Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-22.11";
    flake-utils.url = "github:numtide/flake-utils";
    nur.url = "github:nix-community/NUR";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    common-config.url = "github:misumisumi/nixos-common-config";
    nvimdots.url = "github:misumisumi/nvimdots";
    flakes = {
      url = "github:misumisumi/flakes";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    flake-utils,
    home-manager,
    nixos-generators,
    nixpkgs,
    nixpkgs-stable,
    nur,
    common-config,
    nvimdots,
    flakes,
  }: let
    user = "sumi";
    stateVersion = "23.05"; # For Home Manager

    overlay = {
      nixpkgs,
      pkgs-stable,
      ...
    }: {
      nixpkgs.overlays = [
        nur.overlay
        flakes.overlays.default
      ];
      # ++ (import ./patches {inherit pkgs-stable;});
    };
  in
    {
      # Cluster settings managing colmena
      colmena = (
        import ./machines/cluster {
          inherit nixpkgs;
          inherit (nixpkgs) lib;
        }
      );
    }
    // {
      nixosConfigurations = (
        import ./machines {
          inherit (nixpkgs) lib;
          inherit inputs overlay stateVersion user;
          inherit home-manager nixpkgs nixpkgs-stable nur common-config flakes nvimdots;
        }
      );
    }
    // flake-utils.lib.eachSystem ["x86_64-linux"]
    (system: let
      pkgs = import nixpkgs {
        system = "${system}";
        overlays = [
        ]; # nvfetcherもoverlayする
        config.allowUnfree = true;
      };
      mkcerts = pkgs.callPackage (import ./certs) {};
      myTerraform = pkgs.terraform.withPlugins (tp: [tp.lxd tp.time]);
      myScripts = pkgs.callPackage (import ./scripts) {};
      _pkgs = with pkgs;
      with myScripts; [
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
        deploy
        k
        mkcerts
        mkenv
        mkimg4lxc
        ter
      ];
    in
      with nixpkgs.legacyPackages.${system}; {
        apps = {
          mkcerts = flake-utils.lib.mkApp {drv = mkcerts;};
          ter = flake-utils.lib.mkApp {drv = ter;};
          k = flake-utils.lib.mkApp {drv = k;};
          mkimg4lxc = flake-utils.lib.mkApp {drv = mkimg4lxc;};
        };
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = _pkgs;
          buildInputs = [];
          shellHooks = ''
          '';
        };
      });
}