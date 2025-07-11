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
        "https://cuda-maintainers.cachix.org"
      ];
      trusted-public-keys = [
        "misumisumi.cachix.org-1:f+5BKpIhAG+00yTSoyG/ihgCibcPuJrfQL3M9qw1REY="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      ];
    };
    gc = {
      # 1週間ごとに7日前のイメージを削除
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    package = pkgs.nixVersions.stable; # Enable nixFlakes on system
    registry.nixpkgs.flake = inputs.nixpkgs;

    # flakeの有効化とビルド時の依存関係を維持(オフラインでも再ビルド可能にする)
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs          = true
      keep-derivations      = true
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
        inputs.nur.overlay
        inputs.nixgl.overlay
        inputs.flakes.overlays.default
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
