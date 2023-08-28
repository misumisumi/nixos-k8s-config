{ pkgs, ... }:
{
  deployment.tags = [ "netboot" ];

  imports = [
    ./dnsmasq.nix
    ./nginx.nix
    ./tftpd.nix
  ];

  environment.pathsToLink = [
    "/var/tftp"
  ];
  environment.systemPackages = with pkgs; [
    (setup-netboot-compornents.override
      {
        serverIP = "10.150.20.10";
      })
  ];
}

