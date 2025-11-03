{
  config,
  pkgs,
  pxeInet,
  kexecInet,
  ...
}:
let
  app = "ipxe";
  dataDir = "/var/www/${app}";
  inherit (builtins) head;
in
{
  networking.firewall.allowedTCPPorts = [
    config.services.nginx.defaultHTTPListenPort
    config.services.nginx.defaultSSLListenPort
    8080
  ];
  networking.firewall.allowedUDPPorts = [
    config.services.nginx.defaultHTTPListenPort
    config.services.nginx.defaultSSLListenPort
    8080
  ];
  services.phpfpm.pools.${app} = {
    user = app;
    settings = {
      "listen.owner" = config.services.nginx.user;
      "pm" = "dynamic";
      "pm.max_children" = 32;
      "pm.max_requests" = 500;
      "pm.start_servers" = 2;
      "pm.min_spare_servers" = 2;
      "pm.max_spare_servers" = 5;
      "php_admin_value[error_log]" = "stderr";
      "php_admin_flag[log_errors]" = true;
      "catch_workers_output" = true;
    };
  };
  services.nginx = {
    enable = true;
    # httpConfig = ''
    #   disable_symlinks off;
    # '';
    virtualHosts."${app}" = {
      addSSL = false;
      enableACME = false;
      root = dataDir;
      serverName = "${config.networking.hostName}.${head config.services.dnsmasq.multipleSessions.pxe.domain}";
      listen = [
        {
          addr = "${pxeInet.lan_ip}";
          port = 80;
        }
        {
          addr = "[${pxeInet.lan_ipv6}]";
          port = 80;
        }
      ];
      locations."~ [^/]\.php(/|$)" = {
        extraConfig = ''
          fastcgi_split_path_info ^(.+\.php)(/.+)$;
          fastcgi_pass unix:${config.services.phpfpm.pools.${app}.socket};
          include ${pkgs.nginx}/conf/fastcgi.conf;
        '';
      };
    };
    virtualHosts."kexec" = {
      addSSL = false;
      enableACME = false;
      root = "/var/www/kexec";
      serverName = "${config.networking.hostName}.${head config.services.dnsmasq.multipleSessions.kexec.domain}";
      listen = [
        {
          addr = "${kexecInet.lan_ip}";
          port = 80;
        }
        {
          addr = "[${kexecInet.lan_ipv6}]";
          port = 80;
        }
      ];
    };
  };
  users.users.${app} = {
    isSystemUser = true;
    home = dataDir;
    group = app;
  };
  users.groups.${app} = { };
}
