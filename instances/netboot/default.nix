{ pkgs, ... }:
{
  deployment.tags = [ "netboot" ];

  imports = [
    ../init
    ./dnsmasq.nix
    ./nginx.nix
  ];

}
