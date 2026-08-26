# Headplane: Headscale の Web UI。
# Pi-hole の nginx vhost 経由で 9443 で公開。headplane 自体は内部 3000 で待ち受け。
{
  config,
  lib,
  static,
  group,
  hostname,
  ...
}:
let
  inherit (static.${group}.${hostname}) acme tailnet;
in
{
  sops.secrets = {
    "headplane-cookie-secret" = {
      owner = "headscale";
      group = "headscale";
    };
    "headplane-api-key" = {
      owner = "headscale";
      group = "headscale";
    };
  };

  services.headplane = {
    enable = true;
    settings = {
      headscale = {
        url = "http://127.0.0.1:${toString config.services.headscale.port}";
        config_path = "/etc/headscale/config.yaml";
        public_url = "https://${tailnet.host}";
        # api_key_path = config.sops.secrets."headplane-api-key".path; # Since 26.11
      };
      server = {
        host = "127.0.0.1"; # 内部のみ。nginx が 9443 でプロキシ
        port = 3000;
        cookie_secret_path = config.sops.secrets."headplane-cookie-secret".path;
        cookie_secure = true;
      };
      integration.proc.enabled = true;
    };
  };

  services.nginx.virtualHosts."hp.${acme.certName}" = {
    useACMEHost = acme.certName;
    forceSSL = true;
    listen = [
      {
        addr = "100.64.0.1";
        port = 9443;
        ssl = true;
      }
    ];
    locations = {
      "/" = {
        proxyPass = "http://127.0.0.1:3000/admin/";
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
}
