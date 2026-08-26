# Headscale / DERP / Dex 用の公開 vhost。
# sslh が TCP 443 を占有するため、nginx は 8443 で待ち受ける。
# sslh が TCP 443→8443 に転送し、nginx が SSL で処理する。
{ lib, config, static, group, hostname, ... }:
let
  inherit (static.${group}.${hostname}) acme tailnet;
  fqdn = tailnet.host;
  headscalePort = config.services.headscale.port;
in
{
  services.nginx.virtualHosts.${fqdn} = {
    useACMEHost = acme.certName;
    forceSSL = true;

    # sslh が TCP 443 を占有するため 8443 で待ち受け
    listen = [{
      addr = "0.0.0.0";
      port = 8443;
      ssl = true;
    }];

    locations = {
      # Dex（パス prefix 配信。trailing slash なしで /dex/ を Dex に転送）
      "/dex/" = {
        proxyPass = "http://127.0.0.1:5556";
        proxyWebsockets = true;
      };
      # Headscale 本体 + 内蔵 DERP (/derp) + OIDC callback
      "/" = {
        proxyPass = "http://127.0.0.1:${toString headscalePort}";
        proxyWebsockets = true; # TS2021 Noise の upgrade 対応
      };
    };

    extraConfig = ''
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
    '';
  };
}
