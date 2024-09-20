{ config
, lib
, ...
}:
let
  rootDevice = "/dev/disk/by-id/nvme-SAMSUNG_MZVPV256HDGL-00001_S2SANYAGB00065";
  rootDeviceSize = 238.5; # GB
  # https://docs.oracle.com/cd/E62101_01/html/E62701/zfspools-4.html
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
