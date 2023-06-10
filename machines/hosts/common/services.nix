{
  lib,
  pkgs,
  ...
}:
with lib; {
  security = {
    rtkit.enable = true;
  };

  programs = {
    dconf.enable = true;
    udevil.enable = true;
  };

  services = {
    udisks2.enable = true;
    dbus.packages = with pkgs; [xfce.xfconf];
    gvfs.enable = true; # Mount, trash, and other functions
  };
}