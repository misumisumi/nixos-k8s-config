{ lib
, initial
, ...
}:
{
  imports = [
    #./iscsi.nix
    ../../../apps/pkgs
    ../../../apps/programs
    ../../../apps/services
    ../../../apps/ssh
    ../../../apps/virtualization/incus
    ../../../system
    ../init
    ./hardware-configuration.nix
    ./network.nix
    ./system.nix
    ./zfs.nix
    ./rootfs.nix
  ] ++ lib.optional (! initial) ./additionalfs.nix;
}
