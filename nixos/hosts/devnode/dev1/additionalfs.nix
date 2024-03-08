{ lib
, ...
}:
let
  inherit (import ../../node/utils/lvm-on-luks.nix) deviceProperties;
  devices = {
    a = {
      device = "/dev/disk/by-id/ata-QEMU_HARDDISK_QM00003";
      keyFile = "/.keystore/ceph.key";
      lvs = {
        block = {
          size = "100%FREE";
        };
      };
    };
    b = {
      device = "/dev/disk/by-id/ata-QEMU_HARDDISK_QM00005";
      keyFile = "/.keystore/ceph.key";
      lvs = {
        block = {
          size = "100%FREE";
        };
      };
    };
    c = {
      device = "/dev/disk/by-id/ata-QEMU_HARDDISK_QM00007";
      keyFile = "/.keystore/nfs.key";
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
  environment.etc.crypttab.text = lib.concatStringsSep "\n" (lib.mapAttrsToList (idx: cfg: "CryptedDisk${lib.toUpper idx} ${cfg.device}-part1 ${cfg.keyFile} luks") devices);
}
