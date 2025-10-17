{ lib, ... }:
{
  imports = [
    ../../_init/apps/pkgs
    ../../_init/apps/programs
    ../../_init/apps/services
    ../../_init/apps/ssh
    ../../_init/system
    ./netboot.nix
    ./network.nix
  ];
}
