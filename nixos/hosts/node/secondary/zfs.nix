{
  networking = {
    hostId = "d8280a53";
  };
  boot = {
    extraModprobeConfig = ''
      options zfs zfs_arc_max=4294967296
    '';
  };
}
