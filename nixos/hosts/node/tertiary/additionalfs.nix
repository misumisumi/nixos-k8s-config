{ lib
, ...
}:
let
  inherit (import ../utils/lvm-on-luks.nix) deviceProperties;
  devices = {
    a = {
      device = "/dev/disk/by-id/ata-TOSHIBA_MQ01ABF050_Z8JQT3X8T";
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
  environment.etc.crypttab.text = lib.concatStringsSep "\n" (lib.mapAttrsToList (idx: cfg: "CryptedDisk${lib.toUpper idx} ${cfg.device} ${cfg.keyFile} luks"));
}
