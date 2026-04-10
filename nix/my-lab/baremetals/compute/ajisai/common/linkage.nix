{ lib, pkgs, ... }:
{
  linkage = {
    checkNodes = {
      wait = 5;
      retry = 10;
    };
    highAvailable = {
      enable = true;
      resourceGroup = {
        placeCount = 2;
        pool = "test_pool";
      };
    };
    nodes = {
      ajisai = {
        address = "10.1.254.5";
        type = "combined";
        storagePools = {
          test_pool = {
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
      mao = {
        address = "10.1.254.6";
        type = "combined";
        storagePools = {
          test_pool = {
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
        address = "10.1.254.7";
        type = "combined";
        # storagePools = {
        #   test_pool = {
        #     type = "lvmthin";
        #     volumeGroup = "vg_nvme";
        #     physicalStorage = {
        #       devices = [
        #         "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_incus_linstor"
        #       ];
        #     };
        #   };
        # };
      };
    };
    resourceGroups = [
      # {
      #   name = "test_group";
      #   pool = "test_pool";
      #   placeCount = 2;
      #   resources = [
      #     {
      #       name = "test_resource";
      #       size = "10G";
      #     }
      #     {
      #       name = "test_resource";
      #       size = "10G";
      #     }
      #   ];
      # }
    ];
  };
}
