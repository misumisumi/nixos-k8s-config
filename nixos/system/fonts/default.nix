{ pkgs, ... }:
{
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      moralerspace-nerd-fonts
    ];
  };
}
