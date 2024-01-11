{ lib
, initial
, isVM
, ...
}:
{
  imports = [
    #./iscsi.nix
    ../../apps/pkgs
    ../../apps/programs
    ../../apps/services
    ../../apps/ssh
    ../../apps/virtualization/lxd
    ../../system
    ../init
    ./hardware-configuration.nix
    ./network.nix
    ./system.nix
    ./zfs.nix
  ] ++ lib.optional isVM ./testRootfs.nix
  ++ lib.optional (! isVM) ./rootfs.nix
  ++ lib.optional (! initial) ./additionalfs.nix;
}
