{ lib, ... }:
{
  imports = [
    ../../apps/pkgs
    ../../apps/programs
    ../../apps/services
    ../../apps/ssh
    ../../system
    ./netboot.nix
    ./network.nix
  ];
}
