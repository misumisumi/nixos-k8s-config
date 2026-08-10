{
  lib,
  ...
}:
{
  services.kubernetes.kubelet.extraOpts = lib.strings.concatStringsSep " " [
    "--root-dir=/var/lib/kubelet"
    "--fail-swap-on=false"
  ];

  fileSystems."/var/lib" = {
    device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_incus_var_lib";
    fsType = "ext4";
    autoFormat = true;
  };
}
