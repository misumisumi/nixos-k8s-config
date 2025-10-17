{
  lib,
  pkgs,
  config,
  ...
}:
{
  boot = {
    initrd = {
      supportedFilesystems = [ "zfs" ];
      network.postCommands = ''
        zpool import -a
        echo "zfs load-key -a; killall zfs; exit 0" >> /root/.profile
      '';
    };
    kernelPackages =
      let
        isUnstable = config.boot.zfs.package == pkgs.zfsUnstable;
        zfsCompatibleKernelPackages = lib.filterAttrs (
          name: kernelPackages:
          (builtins.match "linux_[0-9]+_[0-9]+" name) != null
          && (builtins.tryEval kernelPackages).success
          && (
            (!isUnstable && !kernelPackages.${pkgs.zfs.kernelModuleAttribute}.meta.broken)
            || (isUnstable && !kernelPackages.${pkgs.zfs.kernelModuleAttribute}.meta.broken)
          )
        ) pkgs.linuxKernel.packages;
        latestKernelPackage = lib.last (
          lib.sort (a: b: (lib.versionOlder a.kernel.version b.kernel.version)) (
            builtins.attrValues zfsCompatibleKernelPackages
          )
        );
      in
      latestKernelPackage;
    kernelParams = [ "nohibernate" ];
  };
  systemd = {
    services.unmount-keystore = {
      wantedBy = [ "sysinit.target" ];
      after = [
        "local-fs.target"
        "\x2ekeystore.mount"
      ];
      requires = [ "\x2ekeystore.mount" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStartPre = "${pkgs.umount}/bin/umount -R /.keystore";
        ExecStart = "${config.boot.zfs.package}/bin/zfs unload-key PoolRootFS/keystore";
      };
    };
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
