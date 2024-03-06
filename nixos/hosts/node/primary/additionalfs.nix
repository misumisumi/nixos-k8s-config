{ lib
, config
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
  luksSetting = keyName: deviceName: {
    size = "100%";
    content = {
      type = "luks";
      name = "crypted_${deviceName}";
      extraOpenArgs = [ ];
      settings = {
        keyFile = "/.keystore/${keyName}.key";
        allowDiscards = true;
      };
      # additionalKeyFiles = [ "/tmp/additionalSecret.key" ];
      initrdUnlock = false;
      content = {
        type = "lvm_pv";
        vg = "PoolOf${deviceName}";
      };
    };
  };
  devices = {
    a = {
      device = "/dev/disk/by-id/scsi-360030057027804002d1262be2f91e9a2";
      keyFile = "/.keystore/ceph.key";
      lvs = {
        block = {
          size = "100%FREE";
        };
      };
    };
    b = {
      device = "/dev/disk/by-id/scsi-360030057027804002d1262882c5ccb03";
      keyFile = "/.keystore/ceph.key";
      lvs = {
        block = {
          size = "100%FREE";
        };
      };
    };
    c = {
      device = "/dev/disk/by-id/ata-ST8000DM004-2CX188_ZR10J24P";
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
    lvm_vg = lib.mapAttrs' (idx: cfg: lib.nameValuePair "PoolDisk${lib.toUpper idx}" cfg.lvs) devices;
  };
  # ブート時に必要なくかつkeyfileがinitrdでunlockされるzvolに含まれているためcrypttabに記載してstage 2でunlockする
  environment.etc.crypttab.text = lib.concatStringsSep "\n" (lib.mapAttrsToList (idx: cfg: "CryptedDisk${lib.toUpper idx} ${cfg.device} ${cfg.keyFile} luks"));
}
