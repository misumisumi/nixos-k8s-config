{ config
, lib
, ...
}:
let
  rootDevice = "/dev/disk/by-id/nvme-SAMSUNG_MZVPV256HDGL-00001_S2SANYAGB00065";
  rootDeviceSize = 238.5; # GB
  # https://docs.oracle.com/cd/E62101_01/html/E62701/zfspools-4.html
  reservedSize = rootDeviceSize * (1 - 0.89);
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
          encryption = "aes-256-gcm";
          keyformat = "passphrase";
          keylocation = "file:///tmp/rootfs.key";
          relatime = "on";
          xattr = "sa";
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
            size = "1G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/.keystore";
              mountOptions = [ "noauto" ];
            };
            options = {
              encryption = "aes-256-gcm";
              keyformat = "passphrase";
              keylocation = "file:///tmp/keystore.key";
            };
            postCreateHook = ''
              zfs set keylocation="prompt" "PoolRootFS/keystore";
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
            options = {
              "com.sun:auto-snapshot" = "true";
              mountpoint = "legacy";
            };
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
            options = {
              "com.sun:auto-snapshot" = "false";
              mountpoint = "legacy";
            };
          };
          "system/var" = {
            type = "zfs_fs";
            mountpoint = "/var";
            options = {
              "com.sun:auto-snapshot" = "false";
              mountpoint = "legacy";
            };
          };
          "system/var/lib" = {
            type = "zfs_fs";
            mountpoint = "/var/lib";
            options = {
              "com.sun:auto-snapshot" = "true";
              mountpoint = "legacy";
            };
          };
          "system/var/lib/incus" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/incus";
            options = {
              "com.sun:auto-snapshot" = "true";
              mountpoint = "legacy";
            };
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
            options = {
              "com.sun:auto-snapshot" = "false";
              mountpoint = "legacy";
            };
          };
        };
      };
    };
  };
}
