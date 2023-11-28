{ config, hostID, ... }:
{
  networking = {
    useDHCP = true;
    hostId = hostID;
  };
  boot = {
    supportedFilesystems = [ "zfs" ];
    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
    kernelModules = [ "nohibernate" ];
    extraModprobeConfig = ''
      options zfs zfs_arc_max=4294967296
    '';
    zfs = {
      requestEncryptionCredentials = [ "nixos" ];
      forceImportRoot = false;
    };
  };
  services.zfs = {
    trim.enable = true;
    autoScrub.enable = true;
    autoSnapshot = {
      enable = true;
    };
  };
}
