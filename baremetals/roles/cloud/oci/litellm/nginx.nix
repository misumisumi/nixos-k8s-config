# nginx リバースプロキシ（公開）。
# Cloudflare Tunnel からのみ到達し、LiteLLM の /v1 (OpenAI 互換 API) 以外は遮断する。
{
  static,
  group,
  hostname,
  ...
}:
let
  inherit (static.${group}.${hostname}) acme litellm;
in
{
  services.nginx.appendHttpConfig = ''
    limit_req_zone $binary_remote_addr zone=litellm:10m rate=20r/s;
  '';

  services.nginx.virtualHosts."litellm" = {
    serverName = litellm.fqdn;
    useACMEHost = acme.certName;
    forceSSL = true;
    listen = [
      {
        addr = "127.0.0.1";
        port = 9444;
        ssl = true;
      }
    ];

    locations = {
      # OpenAI 互換 API のみ公開
      "/v1/" = {
        proxyPass = "http://127.0.0.1:4000";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_buffering off;
          proxy_read_timeout 600s;
          proxy_send_timeout 600s;
          limit_req zone=litellm burst=30 nodelay;
        '';
      };
      # それ以外（/ui, /key 等）は公開しない
      "/" = {
        return = "403";
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
