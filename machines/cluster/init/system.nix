{stateVersion, ...}: {
  time.timeZone = "Asia/Tokyo"; # Time zone and internationalisation

  system = {
    inherit stateVersion;
    # NixOS settings
    autoUpgrade = {
      # Allow auto update
      enable = false;
    };
  };
}