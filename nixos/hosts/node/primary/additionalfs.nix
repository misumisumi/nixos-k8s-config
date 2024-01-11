{ lib
, ...
}:
let
  canUseCapacity = 0.89; # %
  properties = device: idx: {
    type = "disk";
    inherit device;
    content = {
      type = "gpt";
      partitions = {
        zfs = {
          size = "100%";
          content = {
            type = "zfs";
            pool = "PoolDisk${lib.toUpper idx}";
          };
        };
      };
    };
  };
  type = "zpool";
  options = {
    ashift = "12";
    autotrim = "on";
  };
  rootFsOptions = keyName: {
    "com.sun:auto-snapshot" = "false";
    acltype = "posixacl";
    atime = "on";
    canmount = "off";
    compression = "zstd";
    dnodesize = "auto";
    relatime = "on";
    xaattr = "sa";
    encryption = "aes-256-gcm";
    keyformat = "passphrase";
    keylocation = "file:///.keystore/${keyName}.key";
  };
  reservedDataset = reservedSize: {
    type = "zfs_fs";
    options = {
      mountpoint = "none";
      canmount = "off";
      quota = "${builtins.toString reservedSize}G";
      reservation = "${builtins.toString reservedSize}G";
    };
  };
  devices = {
    a =
      let
        diskSize = 465; #GB
        reservedSize = diskSize - (diskSize * canUseCapacity);
      in
      {
        device = "/dev/disk/by-id/ata-TOSHIBA_MQ01ABF050_46FFCCZBT";
        zfs = {
          inherit type options;
          mountpoint = "/storageA";
          rootFsOptions = rootFsOptions "ceph";
          datasets = {
            reserved = reservedDataset reservedSize;
            cephVol = {
              type = "zfs_volume";
              size = "${builtins.toString (diskSize * canUseCapacity - 1)}G";
            };
          };
        };
      };
    b =
      let
        diskSize = 465; #GB
        reservedSize = diskSize - (diskSize * canUseCapacity);
      in
      {
        device = "/dev/disk/by-id/ata-TOSHIBA_MQ01ABF050_Y8KCTYB7T";
        zfs = {
          inherit type options;
          mountpoint = "/storageB";
          rootFsOptions = rootFsOptions "ceph";
          datasets = {
            reserved = reservedDataset reservedSize;
            cephVol = {
              type = "zfs_volume";
              size = "${builtins.toString (diskSize * canUseCapacity - 1)}G";
            };
          };
        };
      };
    c =
      let
        diskSize = 7452; #GB
        reservedSize = diskSize - (diskSize * canUseCapacity);
      in
      {
        device = "/dev/disk/by-id/ata-ST8000DM004-2CX188_WSC1KCXK";
        zfs = {
          inherit type options;
          mountpoint = "/storageC";
          rootFsOptions = rootFsOptions "nfs";
          datasets = {
            reserved = reservedDataset reservedSize;
            nfsVol = {
              type = "zfs_volume";
              size = "${builtins.toString (diskSize * canUseCapacity - 1)}G";
              options = {
                "com.sun:auto-snapshot" = "true";
              };
            };
          };
        };
      };
  };
in
{
  disko.devices = {
    disk = lib.mapAttrs (name: device: properties device.device name) devices;
    zpool = lib.mapAttrs' (name: device: lib.nameValuePair "PoolDisk${lib.toUpper name}" device.zfs) devices;
  };
}
