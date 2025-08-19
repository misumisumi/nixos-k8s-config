{ config
, lib
, pkgs
, ...
}:
let
  rootDevice = "/dev/disk/by-id/ata-QEMU_HARDDISK_QM00001";
  rootDeviceSize = 32.0; # GB
  reservedSize = rootDeviceSize - (rootDeviceSize * 0.89);
  inherit (import ../../node/utils/root-on-zfs.nix) defaultPartions defaultRootFS;
in
{
  disko.devices = {
    disk = {
      root = defaultPartions rootDevice;
    };
    zpool = {
      PoolRootFS = defaultRootFS reservedSize;
    };
  };
}
