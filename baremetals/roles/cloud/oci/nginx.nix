{
  lib,
  config,
  static,
  group,
  hostname,
  ...
}:
let
  inherit (lib) removeNetmask;
  acme = static.${group}.${hostname}.acme;
  fqdn = "pihole.${acme.certName}"; # pihole.oci.misumi-sumi.com
in
{
  # Cloudflare DNS-01 用の資格情報(実体は sops で暗号化)
  sops.secrets."acme-env" = { };

  security.acme = {
    acceptTerms = true;
    defaults.email = acme.email;
    certs.${acme.certName} = {
      domain = acme.certName;
      extraDomainNames = [ "*.${acme.certName}" ];
      dnsProvider = "cloudflare";
      environmentFile = config.sops.secrets."acme-env".path;
      group = "nginx";
    };
  };

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    defaultListen = [
      {
        addr = "";
      }
    ];
    virtualHosts.${fqdn} = {
      useACMEHost = acme.certName;
      forceSSL = true;
      # wg0 アドレスのみに bind → トンネル経由専用
      listen = [
        {
          addr = "127.0.0.1";
          port = 9443;
          ssl = true;
        }
        {
          addr = removeNetmask static.${group}.${hostname}.wireguard.serverAddress;
          port = 9443;
          ssl = true;
        }
      ];
      locations."/" = {
        proxyPass = "http://127.0.0.1:8080";
        proxyWebsockets = true;
      };
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        add_header Strict-Transport-Security "max-age=63072000" always;
      '';
    };
  };
}
