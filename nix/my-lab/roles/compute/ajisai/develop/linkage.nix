{ lib, ... }:
let
  inherit (lib) importTOML;
  static = importTOML ../../../static_dev.toml;
in
{
  linkage = {
    checkNodes = {
      wait = 5;
      retry = 10;
    };
    highAvailable = {
      enable = true;
      virtualIP = {
        # address = "10.10.10.100";
        # cidr = "32";
        address = "192.168.20.100";
        cidr = "24";
      };
      resourceGroup = {
        placeCount = 2;
        pool = "dev_pool";
      };
    };
    nodes = {
      ajisai = {
        isPrimary = true;
        address = static.compute.ajisai.routerId;
        type = "combined";
        storagePools = {
          dev_pool = {
            type = "lvmthin";
            volumeGroup = "vg_nvme";
            physicalStorage = {
              devices = [
                "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_incus_linstor"
              ];
            };
          };
        };
      };
      mai = {
        address = static.compute.mai.routerId;
        type = "combined";
        storagePools = {
          dev_pool = {
            type = "lvmthin";
            volumeGroup = "vg_nvme";
            physicalStorage = {
              devices = [
                "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_incus_linstor"
              ];
            };
          };
        };
      };
      satsuki = {
        address = static.compute.satsuki.routerId;
        type = "combined";
      };
    };
    resourceGroups = [ ];
    gateway = {
      nfs = {
        name = "dev_nfs_varlib";
        virtualIP = "10.10.10.101/32";
        sizes = [ "32G" ];
        allowedIPs = "10.10.10.0/24";
        filesystem = "ext4";
        resourceGroup = "dev_pool";
      };
    };
  };
}
