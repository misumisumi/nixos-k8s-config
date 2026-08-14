{
  lib,
  config,
  pkgs,
  static,
  group,
  hostname,
  ...
}:
let
  inherit (builtins) head;
  inherit (lib) mapAttrsToList;
  manageIP = lib.removeNetmask static.${group}.${hostname}.networks.manage.address;
in
{
  systemd = {
    services.nginx.wants = [ "pre-nginx.service" ];
    services.pre-nginx = {
      description = "Set nginx data directory permissions";
      after = [ "nginx.service" ];
      wants = [ "nginx.service" ];
      script =
        let
          src = ./www;
          dst = "/var/www";
        in
        ''
          while read -r path; do
            rel="''${path#${src}/}"
            parent="$(dirname "${dst}/$rel")"
            mkdir -p "$parent"
            [ -d "${dst}/$rel" ] && rm -rf "${dst}/$rel"
            cp -r "$path" "${dst}/$rel"
          done< <(find ${src} -type f)
        '';
    };
  };

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
  services.phpfpm.pools.images = {
    user = "images";
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
    virtualHosts = {
      images = {
        addSSL = false;
        enableACME = false;
        root = "/var/www/images";
        serverName = "${config.networking.hostName}.${head config.services.dnsmasq.multipleSessions.images.domain}";
        listen = [
          {
            addr = "${manageIP}";
            port = 80;
          }
        ];
        locations = {
          "~ [^/]\.php(/|$)" = {
            extraConfig = ''
              fastcgi_split_path_info ^(.+\.php)(/.+)$;
              fastcgi_pass unix:${config.services.phpfpm.pools.images.socket};
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

  users.users.images = {
    isSystemUser = true;
    home = "${config.services.nginx.virtualHosts.images.root}";
    group = "images";
  };
  users.groups.images = { };
}
