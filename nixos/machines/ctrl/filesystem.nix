{ lib, ... }:
let
  root_disk = "/dev/sdx";
  # raidz_disks = [ "/dev/sdx" "/dev/sdy" ];
  raidz_disks = [ ];
in
{
  disko.devices = {
    disk = {
      root = {
        type = "disk";
        device = "/dev/sdx";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "128M";
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
                pool = "PoolCtrl";
              };
            };
          };
        };
      };
    } // lib.genAttrs raidz_disks (device: {
      type = "disk";
      name = lib.removePrefix "_" (builtins.replaceStrings [ "/" ] [ "_" ] device);
      inherit device;
      content = {
        type = "gpt";
        partitions = {
          zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "PoolScsi";
            };
          };
        };
      };
    })
    ;
    zpool = {
      PoolCtrl = {
        type = "zpool";
        rootFsOptions = {
          compression = "zstd";
          "com.sun:auto-snapshot" = "false";
        };
        datasets = {
          # zfs_testvolume = {
          #   type = "zfs_volume";
          #   size = "10M";
          #   content = {
          #     type = "filesystem";
          #     format = "ext4";
          #     mountpoint = "/ext4onzfs";
          #   };
          # };
          reserved = {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
              canmount = "off";
              quota = "1G";
              reservation = "1G";
            };
          };
          system = {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
              # encryption = "aes-256-gcm";
              # keyformat = "passphrase";
              # keylocation = "file:///tmp/secret.key";
              compression = "zstd";
              "com.sun:auto-snapshot" = "false";
            };
            # use this to read the key during boot
            # postCreateHook = ''
            #   zfs set keylocation="prompt" "PoolCtrl/system";
            # '';
          };
          "system/root" = {
            type = "zfs_fs";
            mountpoint = "/";
          };
          "system/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            options."com.sun:auto-snapshot" = "true";
          };
          local = {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
              compression = "zstd";
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
