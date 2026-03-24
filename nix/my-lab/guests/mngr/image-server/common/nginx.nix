{
  lib,
  config,
  pkgs,
  static,
  ...
}:
let
  inherit (builtins) listToAttrs head map;
  inherit (lib) mapAttrsToList nameValuePair;
  initialApp = {
    app = "initial";
    dataDir = "/var/www";
  };
  manageApp = {
    app = "manage";
    dataDir = "/var/www/kexec";
  };
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
  services.phpfpm.pools = listToAttrs (
    map
      (
        x:
        nameValuePair x.app {
          user = x.app;
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
        }
      )
      [
        initialApp
        manageApp
      ]
  );
  services.nginx = {
    enable = true;
    virtualHosts = {
      "${initialApp.app}" = {
        addSSL = false;
        enableACME = false;
        root = initialApp.dataDir;
        serverName = "${config.networking.hostName}.${head config.services.dnsmasq.multipleSessions.initial.domain}";
        listen = [
          {
            addr = "${static.initial.ip}";
            port = 80;
          }
        ];
        locations = {
          "~ [^/]\.php(/|$)" = {
            extraConfig = ''
              fastcgi_split_path_info ^(.+\.php)(/.+)$;
              fastcgi_pass unix:${config.services.phpfpm.pools.${initialApp.app}.socket};
              include ${pkgs.nginx}/conf/fastcgi.conf;
            '';
          };
        };
      };
      "${manageApp.app}" = {
        addSSL = false;
        enableACME = false;
        root = manageApp.dataDir;
        serverName = "${config.networking.hostName}.${head config.services.dnsmasq.multipleSessions.manage.domain}";
        listen = [
          {
            addr = "${static.initial.ip}";
            port = 80;
          }
          {
            addr = "${static.manage.ip}";
            port = 80;
          }
        ];
        locations = {
          "~ [^/]\.php(/|$)" = {
            extraConfig = ''
              fastcgi_split_path_info ^(.+\.php)(/.+)$;
              fastcgi_pass unix:${config.services.phpfpm.pools.${manageApp.app}.socket};
              include ${pkgs.nginx}/conf/fastcgi.conf;
            '';
          };
        };
      };
    };
  };
  systemd.services.nginx.after = mapAttrsToList (
    name: _: "dnsmasq@${name}.service"
  ) config.services.dnsmasq.multipleSessions;
  users.users = listToAttrs (
    map
      (
        x:
        nameValuePair x.app {
          isSystemUser = true;
          home = x.dataDir;
          group = x.app;
        }
      )
      [
        initialApp
        manageApp
      ]
  );
  users.groups = listToAttrs (
    map (x: nameValuePair x.app { }) [
      initialApp
      manageApp
    ]
  );
}
