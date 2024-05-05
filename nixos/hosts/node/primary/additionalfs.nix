{ lib
, ...
}:
let
  inherit (import ../utils/lvm-on-luks.nix) deviceProperties;
  devices = {
    a = {
      device = "/dev/disk/by-id/scsi-360030057027804002d1262be2f91e9a2";
      keyFile = "/tmp/ceph.key";
      keyFilePath = "/.keystore/ceph.key";
      lvs = {
        block = {
          size = "100%FREE";
        };
      };
    };
    b = {
      device = "/dev/disk/by-id/scsi-360030057027804002d1262882c5ccb03";
      keyFile = "/tmp/ceph.key";
      keyFilePath = "/.keystore/ceph.key";
      lvs = {
        block = {
          size = "100%FREE";
        };
      };
    };
    c = {
      device = "/dev/disk/by-id/ata-ST8000DM004-2CX188_ZR10J24P";
      keyFile = "/tmp/nfs.key";
      keyFilePath = "/.keystore/nfs.key";
      lvs = {
        block = {
          size = "100%FREE";
        };
      };
    };
  };
in
{
  disko.devices = {
    disk = lib.mapAttrs (idx: cfg: deviceProperties cfg.device (lib.toUpper idx) cfg.keyFile) devices;
    lvm_vg = lib.mapAttrs' (idx: cfg: lib.nameValuePair "PoolDisk${lib.toUpper idx}" { type = "lvm_vg"; inherit (cfg) lvs; }) devices;
  };
  # ブート時に必要なくかつkeyfileがinitrdでunlockされるzvolに含まれているためcrypttabに記載してstage 2でunlockする
  environment.etc.crypttab.text = lib.concatStringsSep "\n" (lib.mapAttrsToList (idx: cfg: "CryptedDisk${lib.toUpper idx} ${cfg.device}-part1 ${cfg.keyFilePath} luks") devices);
}
