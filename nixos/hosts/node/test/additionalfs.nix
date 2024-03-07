{ lib
, ...
}:
let
  deviceProperties = device: idx: keyFile: {
    type = "disk";
    inherit device;
    content = {
      type = "gpt";
      partitions.luks = {
        size = "100%";
        content = {
          type = "luks";
          name = "CryptedDisk${idx}";
          extraOpenArgs = [ ];
          settings = {
            inherit keyFile;
            allowDiscards = true;
          };
          # additionalKeyFiles = [ "/tmp/additionalSecret.key" ];
          initrdUnlock = false;
          content = {
            type = "lvm_pv";
            vg = "PoolDisk${idx}";
          };
        };
      };
    };
  };
  devices = {
    a = {
      device = "/dev/disk/by-id/ata-QEMU_HARDDISK_QM00005";
      keyFile = "/.keystore/ceph.key";
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
