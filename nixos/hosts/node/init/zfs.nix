{ lib, config, pkgs, ... }:
{
  systemd = {
    services.unload-zfs = {
      requiredBy = [ "cryptsetup.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
        ExecStartPre = "${pkgs.umount}/bin/umount -R /.keystore";
        ExecStart = "${config.boot.zfs.package}/bin/zfs unload-key PoolRootFS/keystore";
      };
    };
    tmpfiles.rules = [ "d /.keystore 0700 root root -" ];
  };
  boot = {
    initrd.supportedFilesystems = [ "zfs" ];
    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
    kernelParams = [ "nohibernate" ];
  };
  services.zfs = {
    trim.enable = true;
    autoScrub.enable = true;
    autoSnapshot = {
      enable = true;
      daily = 7;
      flags = "-k -p --utc";
      frequent = 15;
      hourly = 24;
      monthly = 12;
      weekly = 4;
    };
  };
}
