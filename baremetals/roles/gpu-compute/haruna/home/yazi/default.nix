{ lib, pkgs, ... }:
let
  inherit (lib) importTOML;
in
{
  home.packages = with pkgs; [
    exif
    mediainfo
  ];
  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;

    theme = importTOML ./theme.toml;
  };
}
