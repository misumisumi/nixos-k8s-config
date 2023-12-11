{ lib
, vmTest ? false
, ...
}:
let
  root_device = "/dev/disk/by-id/nvme-SAMSUNG_MZVLW256HEHP-000H1_S340NX0K748767";
  root_device_size = 466.8; # GB
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
                pool = "PoolPrimary";
              };
            };
          };
        };
      };
    };
    zpool = {
      PoolPrimary = {
        type = "zpool";
        mountpoint = "/";
        rootFsOptions = {
          compression = "zstd";
          "com.sun:auto-snapshot" = "false";
        }
        // lib.optionalAttrs (! vmTest) {
          encryption = "aes-256-gcm";
          keyformat = "passphrase";
          keylocation = "file:///tmp/secrets/primaryfs.key";
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
          home = {
            type = "zfs_fs";
            mountpoint = "/home";
            options."com.sun:auto-snapshot" = "true";
          };
          lxd = {
            type = "zfs_fs";
            mountpoint = "/var/lib/lxd";
            options."com.sun:auto-snapshot" = "true";
          };
          nix = {
            type = "zfs_fs";
            mountpoint = "/nix";
          };
        };
      } // lib.optionalAttrs (! vmTest) {
        # use this to read the key during boot
        postCreateHook = ''
          zfs set keylocation="prompt" "PoolPrimary";
        '';
      };
    };
  };
}
