{ pkgs, ... }:
{
  services = {
    udisks2.enable = true;
    dbus.packages = with pkgs; [ xfce.xfconf ];
    gvfs.enable = true; # Mount, trash, and other functions
  };
}
