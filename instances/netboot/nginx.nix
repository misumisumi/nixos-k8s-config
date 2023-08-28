{ config, ... }:
{
  networking.firewall.allowedTCPPorts = [
    config.services.nginx.defaultHTTPListenPort
    config.services.nginx.defaultSSLListenPort
  ];
  services.nginx = {
    enable = true;
  };
}
