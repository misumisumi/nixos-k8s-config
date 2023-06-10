# For
{pkgs, ...}: {
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

  fonts = {
    enableDefaultFonts = true;
    fontconfig = {
      defaultFonts = {
        serif = ["Source Han Serif"];
        sansSerif = ["Source Han Sans"];
        monospace = ["Source Han Mono"];
        emoji = ["Noto Color Emoji"];
      };
    };
    fonts = with pkgs; [
      noto-fonts-emoji

      source-han-sans
      source-han-serif
      source-han-mono
    ];
  };
  documentation = {
    man.generateCaches = true;
  };
}