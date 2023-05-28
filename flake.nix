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
        import ./machines/terraform {
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
      overlays.default = final: prev: {mkcerts = final.callPackage (import ./certs) {};};
    }
    // flake-utils.lib.eachSystem ["x86_64-linux"]
    (system: let
      pkgs = import nixpkgs {
        system = "${system}";
        overlays = [
          self.overlays.default
        ]; # nvfetcherもoverlayする
        config.allowUnfree = true;
      };
      myTerraform = pkgs.terraform.withPlugins (tp: [tp.libvirt tp.lxd]);
      ter = pkgs.writeShellScriptBin "ter" ''
        ${myTerraform}/bin/terraform $@ && \
          ${myTerraform}/bin/terraform show -json | ${pkgs.jq}/bin/jq > show.json
      '';
      k = pkgs.writeShellScriptBin "k" ''
        ${pkgs.kubectl}/bin/kubectl --kubeconfig certs/generated/kubernetes/admin.kubeconfig $@
      '';
      mkimg4lxc = pkgs.writeShellScriptBin "mkimg4lxc" ''
        lxc image import --alias nixos ''$(${pkgs.nixos-generators}/bin/ixos-generate -f lxc-metadata) ''$(${pkgs.nixos-generators}/bin/nixos-generate -f lxc --flake ".#terraform-lxc")
      '';
      _pkgs = with pkgs; [
        # software for deployment
        colmena
        jq
        libxslt
        myTerraform

        # software for testing
        etcd
        kubectl

        # scripts
        mkcerts
        ter
        k
        mkimg4lxc
      ];
    in
      with nixpkgs.legacyPackages.${system}; {
        packages = {
          mkcerts = pkgs.mkcerts;
        };
        apps = {
          mkcerts = flake-utils.lib.mkApp {drv = pkgs.mkcerts;};
        };
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = _pkgs;
          buildInputs = [];
          shellHooks = ''
            alias k="kubectl --kubeconfig certs/generated/kubernetes/admin.kubeconfig"
          '';
        };
      });
}