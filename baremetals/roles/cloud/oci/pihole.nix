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
  inherit (lib) removeNetmask;
  wgAddress = removeNetmask static.${group}.${hostname}.wireguard.serverAddress;

  # Replicate the module's resolved settings (with the pwhash placeholder)
  # so we can materialise a real, secret-populated /etc/pihole/pihole.toml.
  baseToml =
    (pkgs.formats.toml { }).generate "pihole-config-init.toml"
      config.services.pihole-ftl.settings;
  acme = static.${group}.${hostname}.acme;
in
{
  sops.secrets = {
    "pihole/pwhash" = { };
  };
  # Disable the module's read-only store symlink; we write the file ourselves.
  environment.etc."pihole/pihole.toml".enable = false;

  networking.firewall.extraForwardRules = "";

  services.nginx.virtualHosts."pihole.${acme.certName}" = {
    useACMEHost = acme.certName;
    forceSSL = true;
    listen = [
      {
        addr = "${wgAddress}";
        port = 9443;
        ssl = true;
      }
    ];
    locations = {
      # Pi-hole dashboard
      "/" = {
        proxyPass = "http://127.0.0.1:8080";
        proxyWebsockets = true;
      };
    };
    extraConfig = ''
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
      add_header Strict-Transport-Security "max-age=63072000" always;
    '';
  };

  services = {
    resolved = {
      enable = true;
      settings.Resolve = {
        DNSStubListener = "no";
        DNS = "127.0.0.1";
        FallbackDNS = [
          "1.1.1.1"
          "2606:4700:4700::1111"
          "8.8.8.8"
          "2001:4860:4860::8888"
        ];
      };
    };

    pihole-ftl = {
      enable = true;
      lists = [
        {
          url = "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/filters/filter_15_DnsFilter/filter.txt";
          description = "Adguard DNS filter";
          type = "block";
          enabled = true;
        }
        {
          url = "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/filters/filter_7_Japanese/filter.txt";
          description = "Adguard Japanese filter";
          type = "block";
          enabled = true;
        }
      ];
      settings = {
        dns = {
          upstreams = [
            "1.1.1.1"
            "8.8.8.8"
            "1.0.0.1"
          ];
          port = 53;
          listeningMode = "ALL";
        };
        webserver.api = {
          # placeholder; replaced at runtime by pre-pihole-ftl.service
          pwhash = "@PIHOLE_PWHASH@";
          cli_pw = true;
        };
        # Pi-hole v6 は /etc/dnsmasq.d をデフォルトで読まないため dnsmasq_lines で宣言。
        # oci.misumi-sumi.com ゾーン全体をWGトンネル内アドレスに解決。
        misc.dnsmasq_lines = [
          "address=/.oci.misumi-sumi.com/${wgAddress}"
          "server=/misumi-sumi.com/${static.${group}.${hostname}.pihole.home.forwardIP}"
        ];
      };
    };
    # Dashboard served by pihole-web on port 8080 (also sets FTL webserver.port).
    pihole-web = {
      enable = true;
      ports = [ 8080 ];
    };
  };

  # Generate the real pihole.toml from the store base + the sops pwhash,
  # ordered before pihole-ftl / pihole-web start.
  systemd.services.pre-pihole-ftl = {
    requiredBy = [
      "pihole-ftl.service"
      "pihole-web.service"
    ];
    before = [
      "pihole-ftl.service"
      "pihole-web.service"
    ];
    after = [ "sops-install-secrets.service" ];
    restartIfChanged = true;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      tmp=$(mktemp)
      sec=$(mktemp)
      tr -d '\n' < ${config.sops.secrets."pihole/pwhash".path} > "$sec"
      cp -f ${baseToml} "$tmp"
      ${pkgs.replace-secret}/bin/replace-secret '@PIHOLE_PWHASH@' "$sec" "$tmp"
      install -o pihole -g pihole -m400 "$tmp" /etc/pihole/pihole.toml
      rm -f "$tmp" "$sec"
    '';
  };
}
