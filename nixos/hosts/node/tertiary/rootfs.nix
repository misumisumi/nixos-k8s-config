{ config
, lib
, tag
, ...
}:
let
  rootDevice = "/dev/disk/by-id/ata-TOSHIBA_THNSNJ256GCSU_84MS106NT7SW";
  rootDeviceSize = 238.5; # GB
  reservedSize = rootDeviceSize - (rootDeviceSize * 0.89);
in
{
  boot.postBootCommands = ''
    ${config.boot.zfs.package}/bin/zfs unload-key PoolRootFS/keystore
  '';
  disko.devices = {
    disk = {
      root = {
        type = "disk";
        device = rootDevice;
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "256M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "PoolRootFS";
              };
            };
          };
        };
      };
    };
    zpool = {
      PoolRootFS = {
        type = "zpool";
        options = {
          ashift = "12";
          autotrim = "on";
        };
        mountpoint = "/";
        rootFsOptions = {
          "com.sun:auto-snapshot" = "false";
          acltype = "posixacl";
          atime = "on";
          canmount = "off";
          compression = "zstd";
          dnodesize = "auto";
          relatime = "on";
          xattr = "sa";
          encryption = "aes-256-gcm";
          keyformat = "passphrase";
          keylocation = "file:///tmp/${tag}/rootfs.key";
        };
        postCreateHook = ''
          zfs set keylocation="prompt" "PoolRootFS";
        '';
        datasets = {
          reserved = {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
              canmount = "off";
              quota = "${builtins.toString reservedSize}G";
              reservation = "${builtins.toString reservedSize}G";
            };
          };
          keystore = {
            type = "zfs_volume";
            size = "2G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/.keystore";
              mountOptions = [ "noauto" ];
            };
            options = {
              encryption = "aes-256-gcm";
              keyformat = "passphrase";
              keylocation = "file:///tmp/${tag}/keystore.key";
            };
            postCreateHook = ''
              zfs set keylocation="prompt" "PoolRootFS/keystore";
            '';
            postMountHook = ''
              if [ -d /tmp/${tag} ]; then
                find /tmp/${tag} -type f | grep -vE "keystore|rootfs" | xargs -I{} cp {} /mnt/.keystore/
              fi
            '';
          };
          user = {
            type = "zfs_fs";
            options = {
              canmount = "off";
              "com.sun:auto-snapshot" = "true";
            };
          };
          "user/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
          };
          system = {
            type = "zfs_fs";
            options = {
              canmount = "off";
              "com.sun:auto-snapshot" = "false";
            };
          };
          "system/root" = {
            type = "zfs_fs";
            mountpoint = "/";
            options."com.sun:auto-snapshot" = "false";
          };
          "system/var" = {
            type = "zfs_fs";
            mountpoint = "/var";
            options."com.sun:auto-snapshot" = "false";
          };
          "system/var/lib" = {
            type = "zfs_fs";
            mountpoint = "/var/lib";
            options."com.sun:auto-snapshot" = "false";
          };
          "system/var/lib/incus" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/incus";
            options."com.sun:auto-snapshot" = "true";
          };
          "local" = {
            type = "zfs_fs";
            options = {
              canmount = "off";
              "com.sun:auto-snapshot" = "false";
            };
          };
          "local/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
          };
        };
      };
    };
  };
}
