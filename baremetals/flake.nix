{
  description = "Baremetal server configuration";
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
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nur.url = "github:nix-community/NUR";
    flakes.url = "github:misumisumi/flakes";

    openwrt-imagebuilder = {
      url = "github:astro/nix-openwrt-imagebuilder";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nixos-linstor = {
      url = "git+ssh://git@github.com/misumisumi/nixos-linstor.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pcp = {
      url = "github:performancecopilot/pcp";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        microvm.follows = "microvm";
      };
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    microvm = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    homelab-modules.url = "path:../modules";
  };

  outputs =
    inputs@{
      self,
      flake-parts,
      openwrt-imagebuilder,
      ...
    }:
    let
      # lib extended by ./patches/lib.nix (also loaded by ./patches/default.nix)
      lib = inputs.nixpkgs.lib.extend (import ./patches/lib.nix);
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [
        inputs.devshell.flakeModule
      ];
      flake = {
        overlay = self.overlays.default;
        overlays.default =
          let
            nixpkgs-unstable = import inputs.nixpkgs-unstable {
              system = "x86_64-linux";
              config = {
                allowUnfree = true;
              };
            };
          in
          import ./patches {
            inherit nixpkgs-unstable;
          };
        nixosConfigurations = import ./roles {
          inherit lib inputs self;
        };
      };
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
            overlays = [
              self.overlays.default
              inputs.nixos-linstor.overlays.default
            ];
            config.allowUnfree = true;
          };
          packages =
            let
              mylab-sks8300-8x = import ./roles/switch/sks8300-8x/image.nix {
                pkgs = nixpkgs-unstable;
                inherit openwrt-imagebuilder lib;
              };
            in
            {
              inherit (mylab-sks8300-8x) prod_switch_sks8300-8x dev_switch_sks8300-8x;
              inherit (pkgs)
                linkage
                linkage-gateway
                mkimg-dev-wrt
                mkimg-incus-vm
                mkimg-ipxe
                mkimg-kexec
                mkimg-list
                mkimg-lxc
                mkimg-oci
                mkpasswd-pihole
                ;
              pcp = inputs.pcp.packages.${pkgs.stdenv.hostPlatform.system}.pcp;
            };
        };
    };
}
