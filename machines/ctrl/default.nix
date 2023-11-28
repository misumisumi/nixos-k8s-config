{
  imports = [
    ./hardware-configuration.nix
    #./iscsi.nix
    ./network.nix
    ./system.nix
    ./zfs.nix
    ../init
    ../../system
    ../../apps/pkgs
    ../../apps/programs
    ../../apps/services
    ../../apps/ssh
    ../../apps/virtualization/lxd
  ];
}
