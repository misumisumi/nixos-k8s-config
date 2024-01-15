{ pkgs, ... }:
{
  imports = [
    ../init
    ./autoresources.nix
    ./dnsmasq.nix
    ./nginx.nix
  ];
}
