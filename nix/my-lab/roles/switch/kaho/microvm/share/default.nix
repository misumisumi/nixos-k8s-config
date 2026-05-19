{ config, ... }:
{
  imports = [
    ../../../../share/settings/users.nix
    ./users.nix
  ];
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
