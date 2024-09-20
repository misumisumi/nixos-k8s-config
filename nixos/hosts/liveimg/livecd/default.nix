{ lib, ... }:
{
  imports = [
    ../../../apps/pkgs
    ../../../apps/ssh
    ./livecd.nix
  ];
}
