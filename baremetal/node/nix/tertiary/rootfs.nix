{ config
, lib
, tag
, ...
}:
let
  rootDevice = "/dev/disk/by-id/ata-TOSHIBA_THNSNJ256GCSU_84MS106NT7SW";
  rootDeviceSize = 238.5; # GB
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
