{
  networking = {
    hostId = "21d19935";
  };
  boot = {
    extraModprobeConfig = ''
      options zfs zfs_arc_max=4294967296
    '';
  };
}
