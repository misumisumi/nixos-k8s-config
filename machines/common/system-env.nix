# For
{ lib, pkgs, stateVersion, ... }: with lib; {
  time.timeZone = "Asia/Tokyo"; # Time zone and internationalisation
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "ja_JP.UTF-8/UTF-8"
    ];
    extraLocaleSettings = {
      # Extra locale settings that need to be overwritten
      LC_TIME = "ja_JP.UTF-8";
      LC_MONETARY = "ja_JP.UTF-8";
    };
  };

  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  fonts = { }
    // optionalAttrs (stateVersion <= "23.05") {
    enableDefaultFonts = true;
    fonts = with pkgs; [
      plemoljp-fonts
    ];
  }
    // optionalAttrs (stateVersion > "23.05") {
    enableDefaultPackages = true;
    packages = with pkgs; [
      plemoljp-fonts
    ];
  };
  documentation = {
    man.generateCaches = true;
  };

  environment = {
    variables = {
      TERMINAL = "wezterm";
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    systemPackages = import ./pkgs.nix { inherit pkgs; };
  };
}
