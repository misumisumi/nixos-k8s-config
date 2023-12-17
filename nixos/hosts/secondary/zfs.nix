{ lib, config, ... }:
{
  networking = {
    hostId = "4e21f98c";
  };
  boot = {
    initrd.supportedFilesystems = [ "zfs" ];
    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
    kernelModules = [ "nohibernate" ];
    extraModprobeConfig = ''
      options zfs zfs_arc_max=4294967296
    '';
    supportedFilesystems = [ "zfs" ];
    zfs = {
      forceImportRoot = true;
    };
  };
  services.zfs = {
    trim.enable = true;
    autoScrub.enable = true;
    autoSnapshot = {
      enable = false;
      daily = 7;
      flags = "-k -p --utc";
      frequent = 15;
      hourly = 24;
      monthly = 12;
      weekly = 4;
    };
  };
}
