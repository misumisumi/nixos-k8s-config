{ lib, stateVersion, pkgs, ... }:
with lib; {
  fonts = optionalAttrs (stateVersion <= "23.05")
    {
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
}
