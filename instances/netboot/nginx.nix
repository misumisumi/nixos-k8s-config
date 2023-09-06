{ config, pkgs, nodeIP, ... }:
let
  serverName = "myipxe.com";
in
{
  networking.firewall.allowedTCPPorts = [
    config.services.nginx.defaultHTTPListenPort
    config.services.nginx.defaultSSLListenPort
  ];
  networking.firewall.allowedUDPPorts = [
    config.services.nginx.defaultHTTPListenPort
    config.services.nginx.defaultSSLListenPort
  ];
  services.nginx = {
    enable = true;
    virtualHosts."${serverName}" = {
      addSSL = false;
      enableACME = false;
      # listenAddresses = [ "${nodeIP}:80" ];
      root = "/run/current-system/sw/var/www/${serverName}";
    };
  };
  environment.systemPackages = with pkgs; [
    (setup-netboot-compornents.override
      {
        serverIP = "${nodeIP}";
        serverName = "${serverName}";
      })
  ];
  environment.pathsToLink = [
    "/var/tftp"
    "/var/www/${serverName}"
  ];
}
