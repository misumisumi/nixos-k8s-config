{
  self,
  config,
  ...
}:
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
    # httpConfig = ''
    #   disable_symlinks off;
    # '';
    virtualHosts."homelab-ipxe-server" = {
      addSSL = false;
      enableACME = false;
      # listenAddresses = [ "${nodeIP}:80" ];
      root = "/run/current-system/sw/var/www";
    };
  };
  # environment.systemPackages = [
  #   (pkgs.callPackage ./setup-netboot-compornents.nix {
  #     nixosConfigs = {
  #       inherit (self.nixosConfigurations) netboot;
  #     };
  #     inherit serverName;
  #   })
  # ];
  environment.pathsToLink = [
    "/var/tftp"
    "/var/www"
  ];
}
