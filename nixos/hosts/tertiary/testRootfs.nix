{ lib
, tag
, ...
}:
let
  rootDevice = "/dev/disk/by-id/nvme-SAMSUNG_MZVLW256HEHP-000H1_S340NX0K748767";
  rootDeviceSize = 8; # GB
  # https://docs.oracle.com/cd/E62101_01/html/E62701/zfspools-4.html
  reservedSize = rootDeviceSize - (rootDeviceSize * 0.89);
in
{
  systemd.services.unload-keystore = {
    description = "Unload keystore";
    wantedBy = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/run/wrappers/bin/umount -R /.keystore";
      ExecStartPost = "";
    };
  };
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
        };
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
            };
            postMountHook = ''
              if [ -d /tmp/${tag} ]; then
                find /tmp/${tag} -type f | grep -vE "keystore|rootfs" | xargs -I{} cp {} /mnt/.keystore/
              fi
            '';
          };
          cephMonVol = {
            type = "zfs_volume";
            size = "1G";
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
      };
    };
  };
}
