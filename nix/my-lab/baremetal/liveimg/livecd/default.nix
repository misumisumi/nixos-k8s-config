{ lib, ... }:
{
  imports = [
    ../../_init/apps/pkgs
    ../../_init/apps/ssh
    ./livecd.nix
  ];
}
