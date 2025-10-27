{
  self,
  config,
  pkgs,
  ...
}:
let
  serverName = "homelab-ipxe-server";
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
    # httpConfig = ''
    #   disable_symlinks off;
    # '';
    virtualHosts."${serverName}" = {
      addSSL = false;
      enableACME = false;
      # listenAddresses = [ "${nodeIP}:80" ];
      root = "/run/current-system/sw/var/www/${serverName}";
    };
  };
  environment.systemPackages = [
    (pkgs.callPackage ./setup-netboot-compornents.nix {
      nixosConfigs = {
        inherit (self.nixosConfigurations) netboot first-stage-netboot-image;
      };
      inherit serverName;
    })
  ];
  environment.pathsToLink = [
    "/var/tftp"
    "/var/www"
  ];
}
