{ config
, lib
, isVM
, ...
}:
let
  root_device = "/dev/disk/by-id/ata-KIOXIA-EXCERIA_SATA_SSD_822B70LKKLE4";
  root_device_size = if isVM then 8 else 223.6; # GB
  reserved_size = root_device_size - (root_device_size * 0.85);
in
{
  disko.devices = {
    disk = {
      root = {
        type = "disk";
        device = root_device;
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
        rootFsOptions = {
          compression = "zstd";
          "com.sun:auto-snapshot" = "false";
          mountpoint = "none";
          canmount = "off";
        }
        // lib.optionalAttrs (! isVM) {
          encryption = "aes-256-gcm";
          keyformat = "passphrase";
          keylocation = "file:///tmp/rootfs.key";
        };
        datasets = {
          reserved = {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
              canmount = "off";
              quota = "${builtins.toString reserved_size}G";
              reservation = "${builtins.toString reserved_size}G";
            };
          };
          user = {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
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
              mountpoint = "none";
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
          "system/var/lib/lxd" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/lxd";
            options."com.sun:auto-snapshot" = "true";
          };
          "local" = {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
              canmount = "off";
              "com.sun:auto-snapshot" = "false";
            };
          };
          "local/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
          };
        };
      } // lib.optionalAttrs (! isVM) {
        # use this to read the key during boot
        postCreateHook = ''
          zfs set keylocation="prompt" "PoolRootFS";
        '';
      };
    };
  };
}
