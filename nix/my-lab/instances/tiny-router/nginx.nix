{
  lib,
  config,
  pkgs,
  pxeInet,
  kexecInet,
  ...
}:
let
  inherit (builtins) listToAttrs head map;
  inherit (lib) mapAttrsToList nameValuePair;
  ipxe = rec {
    app = "ipxe";
    dataDir = "/var/www/${app}";
  };
  kexec = rec {
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
        ipxe
        kexec
      ]
  );
  services.nginx = {
    enable = true;
    # httpConfig = ''
    #   disable_symlinks off;
    # '';
    virtualHosts."${ipxe.app}" = {
      addSSL = false;
      enableACME = false;
      root = ipxe.dataDir;
      serverName = "${config.networking.hostName}.${head config.services.dnsmasq.multipleSessions.pxe.domain}";
      listen = [
        {
          addr = "${pxeInet.ip}";
          port = 80;
        }
        {
          addr = "[${pxeInet.ipv6}]";
          port = 80;
        }
      ];
      locations = {
        # "/" = {
        #   extraConfig = ''
        #     allow ${pxeInet.base_ip}.0${pxeInet.ip_prefix};
        #     allow ${pxeInet.base_ipv6}::${pxeInet.ipv6_prefix};
        #     deny all;
        #   '';
        # };
        "~ [^/]\.php(/|$)" = {
          extraConfig = ''
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass unix:${config.services.phpfpm.pools.${ipxe.app}.socket};
            include ${pkgs.nginx}/conf/fastcgi.conf;
          '';
        };
      };
    };

    virtualHosts."${kexec.app}" = {
      addSSL = false;
      enableACME = false;
      root = kexec.dataDir;
      serverName = "${config.networking.hostName}.${head config.services.dnsmasq.multipleSessions.kexec.domain}";
      listen = [
        {
          addr = "${kexecInet.ip}";
          port = 80;
        }
        {
          addr = "[${kexecInet.ipv6}]";
          port = 80;
        }
      ];
      locations = {
        # "/" = {
        #   extraConfig = ''
        #     allow ${kexecInet.base_ip}.0${kexecInet.ip_prefix};
        #     allow ${kexecInet.base_ipv6}::${kexecInet.ipv6_prefix};
        #     deny all;
        #   '';
        # };
        "~ [^/]\.php(/|$)" = {
          extraConfig = ''
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass unix:${config.services.phpfpm.pools.${kexec.app}.socket};
            include ${pkgs.nginx}/conf/fastcgi.conf;
          '';
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
        ipxe
        kexec
      ]
  );
  users.groups = listToAttrs (
    map (x: nameValuePair x.app { }) [
      ipxe
      kexec
    ]
  );
}
