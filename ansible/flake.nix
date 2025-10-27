{
  description = "Playbooks for apps of my k8s cluster";
  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nvfetcher.url = "github:berberman/nvfetcher";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devshell.flakeModule
      ];
      systems = [ "x86_64-linux" ];
      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              (final: prev: {
                python3Packages = prev.python3Packages.override {
                  overrides = pfinal: pprev: {
                    ansible-core = pprev.ansible-core.overridePythonAttrs (old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ pprev.kubernetes ];
                      makeWrapperArgs = (old.makeWrapperArgs or [ ]) ++ [ "--set PYTHONPATH $PYTHONPATH" ];
                    });
                  };
                };
              })
            ];
            config.allowUnfree = true;
          };

          devshells = {
            # nvfetcher = inputs.nvfetcher.packages.${system};
            default =
              let
                myScripts = pkgs.callPackage (import ./scripts) { };
              in
              {
                env =
                  let
                    ANSIBLE_COLLECTIONS_PATH = pkgs.callPackage ./collections { };
                  in
                  [
                    {
                      name = "ANSIBLE_COLLECTIONS_PATH";
                      value = ANSIBLE_COLLECTIONS_PATH;
                    }
                    {
                      name = "ANSIBLE_ROLES_PATH";
                      value = "${ANSIBLE_COLLECTIONS_PATH}/roles";
                    }
                  ];
                packages =
                  with pkgs;
                  with myScripts;
                  [
                    bashInteractive
                    jq
                    yq # python-yq
                    argocd
                    ansible
                    kubectl
                    kubernetes-helm
                    nvfetcher
                    # MyScripts
                    k
                    he
                  ];
              };
          };
        };
    };
}
