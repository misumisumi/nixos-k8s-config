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
  ipxeApp = rec {
    app = "ipxe";
    dataDir = "/var/www/${app}";
  };
  kexecApp = rec {
    app = "kexec";
    dataDir = "/var/www/${app}";
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
  systemd.services."phpfpm-${kexecApp.app}".serviceConfig = {
    ReadWritePaths = [
      "/etc/cockpit/machines.d"
    ];
  };
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
        ipxeApp
        kexecApp
      ]
  );
  services.nginx = {
    enable = true;
    virtualHosts = {
      "${ipxeApp.app}" = {
        addSSL = false;
        enableACME = false;
        root = ipxeApp.dataDir;
        serverName = "${config.networking.hostName}.${head config.services.dnsmasq.multipleSessions.pxe.domain}";
        listen = [
          {
            addr = "${static.pxe.ip}";
            port = 80;
          }
        ];
        locations = {
          "~ [^/]\.php(/|$)" = {
            extraConfig = ''
              fastcgi_split_path_info ^(.+\.php)(/.+)$;
              fastcgi_pass unix:${config.services.phpfpm.pools.${ipxeApp.app}.socket};
              include ${pkgs.nginx}/conf/fastcgi.conf;
            '';
          };
        };
      };
      "${kexecApp.app}" = {
        addSSL = false;
        enableACME = false;
        root = kexecApp.dataDir;
        serverName = "${config.networking.hostName}.${head config.services.dnsmasq.multipleSessions.kexec.domain}";
        listen = [
          {
            addr = "${static.kexec.ip}";
            port = 80;
          }
        ];
        locations = {
          "~ [^/]\.php(/|$)" = {
            extraConfig = ''
              fastcgi_split_path_info ^(.+\.php)(/.+)$;
              fastcgi_pass unix:${config.services.phpfpm.pools.${kexecApp.app}.socket};
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
        ipxeApp
        kexecApp
      ]
  );
  users.groups = listToAttrs (
    map (x: nameValuePair x.app { }) [
      ipxeApp
      kexecApp
    ]
  );
}
