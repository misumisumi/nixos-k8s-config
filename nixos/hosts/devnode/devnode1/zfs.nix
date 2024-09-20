{
  networking = {
    hostId = "fd6ba69c";
  };
  boot = {
    extraModprobeConfig = ''
      options zfs zfs_arc_max=4294967296
    '';
  };
}
