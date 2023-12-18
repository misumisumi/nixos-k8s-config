{
  networking = {
    hostId = "4e21f98c";
  };
  boot = {
    extraModprobeConfig = ''
      options zfs zfs_arc_max=4294967296
    '';
  };
}
