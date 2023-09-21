{ pkgs, ... }:
{
  imports = [
    ../init
    ./dnsmasq.nix
    ./nginx.nix
  ];

}