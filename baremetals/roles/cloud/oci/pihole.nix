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
  # Replicate the module's resolved settings (with the pwhash placeholder)
  # so we can materialise a real, secret-populated /etc/pihole/pihole.toml.
  baseToml =
    (pkgs.formats.toml { }).generate "pihole-config-init.toml"
      config.services.pihole-ftl.settings;
in
{
  sops.secrets = {
    "pihole-pwhash" = { };
  };
  # Disable the module's read-only store symlink; we write the file ourselves.
  environment.etc."pihole/pihole.toml".enable = false;

  networking.firewall.extraForwardRules = "";

  services = {
    resolved = {
      enable = true;
      settings.Resolve = {
        DNSStubListener = "no";
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
          interface = "wg0"; # DNS reachable only over the tunnel
          port = 53;
        };
        webserver.api = {
          # placeholder; replaced at runtime by pre-pihole-ftl.service
          pwhash = "@PIHOLE_PWHASH@";
          cli_pw = true;
        };
        # Pi-hole v6 は /etc/dnsmasq.d をデフォルトで読まないため dnsmasq_lines で宣言。
        # oci.misumi-sumi.com ゾーン全体をトンネル内アドレス(10.250.0.1)に解決。
        misc.dnsmasq_lines = [
          "address=/.oci.misumi-sumi.com/${removeNetmask static.${group}.${hostname}.wireguard.serverAddress}"
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
      tr -d '\n' < ${config.sops.secrets."pihole-pwhash".path} > "$sec"
      cp -f ${baseToml} "$tmp"
      ${pkgs.replace-secret}/bin/replace-secret '@PIHOLE_PWHASH@' "$sec" "$tmp"
      install -o pihole -g pihole -m400 "$tmp" /etc/pihole/pihole.toml
      rm -f "$tmp" "$sec"
    '';
  };
}
