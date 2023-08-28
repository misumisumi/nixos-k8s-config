{
  deployment.tags = [ "netboot" ];

  imports = [
    ./dnsmasq.nix
    ./nginx.nix
    ./tftpd.nix
  ];

  environment.pathsToLink = [
    "/var/www/"
  ];
}