#NOTE: diskless hypervisorでは、tmpfs, squashfsを使用するため一般的なext4やbtrfsのツールは必要ない。
# マウント等で必要であれば別途入れる
{
  pkgs,
  ...
}:
{
  boot.tmp.tmpfsSize = "20%";
  # Include some utilities that are useful for installing or repairing
  # the system.
  environment.systemPackages = [
    pkgs.testdisk # useful for repairing boot problems

    # Hardware-related tools.
    pkgs.sdparm
    pkgs.hdparm
    pkgs.smartmontools # for diagnosing hard disks
    pkgs.pciutils
    pkgs.usbutils
    pkgs.nvme-cli
  ];
  # diskless hypervisor is no need documentation
  documentation.enable = false;
}
