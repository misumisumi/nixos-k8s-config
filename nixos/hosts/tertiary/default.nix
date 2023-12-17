{ lib
, initial ? false
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
    ./additionalfs.nix
    ./hardware-configuration.nix
    ./network.nix
    ./rootfs.nix
    ./system.nix
    ./zfs.nix
  ] ++ lib.optional (! initial) ./post-install.nix;
}
