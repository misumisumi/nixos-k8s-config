{
  config,
  pkgs,
  inputs,
  ...
}:
{
  nix = {
    settings = {
      auto-optimise-store = true; # Optimise syslinks
      substituters = [
        "https://misumisumi.cachix.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "misumisumi.cachix.org-1:f+5BKpIhAG+00yTSoyG/ihgCibcPuJrfQL3M9qw1REY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
    package = pkgs.nixVersions.stable; # Enable nixFlakes on system
    registry.nixpkgs.flake = inputs.nixpkgs;

    # flakeの有効化とビルド時の依存関係を維持しない
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs          = false
      keep-derivations      = false
    '';
  };

  nixpkgs = {
    overlays =
      let
        nixpkgs-unstable = import inputs.nixpkgs-unstable {
          inherit (config.nixpkgs) system;
          config = {
            allowUnfree = true;
          };
        };
      in
      [
        inputs.nur.overlays.default
        inputs.flakes.overlays.default
        inputs.nixos-linstor.overlays.default
        (import ../../../patches { inherit nixpkgs-unstable; })
      ];
    config = {
      allowUnfree = true;
    };
  };
  system = {
    stateVersion = config.system.nixos.release;
    # NixOS settings
    autoUpgrade = {
      # Allow auto update
      enable = false;
      channel = "https://nixos.org/channels/nixos-unstable";
    };
  };
}
