{ lib, stateVersion, pkgs, ... }:
with lib; {
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      plemoljp-fonts
    ];
  };
}
