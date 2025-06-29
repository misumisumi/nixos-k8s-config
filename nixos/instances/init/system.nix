{ config, ... }:
{
  time.timeZone = "Asia/Tokyo"; # Time zone and internationalisation

  system = {
    stateVersion = config.system.nixos.release;
    # NixOS settings
    autoUpgrade = {
      # Allow auto update
      enable = false;
    };
  };
}
