{ config
, lib
, ...
}:
let
  rootDevice = "/dev/disk/by-id/ata-CT500MX500SSD1_2244E680233C";
  rootDeviceSize = 465.8; # GB
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
