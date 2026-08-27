{
  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "virtio_pci"
      "virtio_scsi"
      "usbhid"
    ];
    # Taken from /proc/cmdline of Ubuntu 20.04.2 LTS on OCI
    kernelParams = [
      "nvme.shutdown_timeout=10"
      "nvme_core.shutdown_timeout=10"
      "libiscsi.debug_libiscsi_eh=1"
      "crash_kexec_post_notifiers"

      # VNC console
      "console=tty1"

      # aarch64-linux
      "console=ttyAMA0,115200"
    ];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = false;
      grub.efiInstallAsRemovable = true;
    };
  };
  # https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/configuringntpservice.htm#Configuring_the_Oracle_Cloud_Infrastructure_NTP_Service_for_an_Instance
  networking.timeServers = [ "169.254.169.254" ];

  # disko: GPT + ESP + ext4 root on the OCI block volume (/dev/sda).
  disko.devices = {
    disk.main = {
      device = "/dev/sda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
