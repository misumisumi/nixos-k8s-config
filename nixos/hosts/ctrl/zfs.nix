{ lib, config, ... }:
{
  networking = {
    useDHCP = true;
    hostId = "d8280a53";
  };
  boot = {
    supportedFilesystems = [ "zfs" ];
    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
    kernelModules = [ "nohibernate" ];
    extraModprobeConfig = ''
      options zfs zfs_arc_max=4294967296
    '';
    zfs = {
      requestEncryptionCredentials = [ "system" ];
      forceImportRoot = false;
    };
  };
  services.zfs = {
    trim.enable = true;
    autoScrub.enable = true;
    autoSnapshot = {
      enable = false;
    };
  };
}
