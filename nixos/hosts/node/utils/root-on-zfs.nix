{
  defaultPartions = device: {
    type = "disk";
    inherit device;
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
  defaultRootFS = reservedSize: {
    type = "zpool";
    options = {
      ashift = "12";
      autotrim = "on";
    };
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
      keylocation = "file:///tmp/rootfs.key";
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
}
