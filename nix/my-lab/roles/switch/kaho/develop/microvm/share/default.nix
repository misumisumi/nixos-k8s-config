{ config, ... }:
{
  imports = [
    ../../../../../share/settings/users.nix
    ./users.nix
  ];
  networking = {
    nftables.enable = true;
    firewall.enable = true;
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
