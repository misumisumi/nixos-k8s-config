# nginx リバースプロキシ（公開）。
# Cloudflare Tunnel からのみ到達し、LiteLLM の /v1 (OpenAI 互換 API) 以外は遮断する。
#
# NOTE: cloudflared とは loopback (127.0.0.1) で接続するため origin は HTTP とし、
#       クライアント向け TLS は Cloudflare エッジで終端する。
#       (origin を HTTPS にすると lego 証明書の要否や検証で詰まりやすい)
{
  static,
  group,
  hostname,
  ...
}:
let
  inherit (static.${group}.${hostname}) litellm;
in
{
  services.nginx.appendHttpConfig = ''
    limit_req_zone $binary_remote_addr zone=litellm:10m rate=20r/s;
  '';

  services.nginx.virtualHosts."litellm" = {
    serverName = litellm.fqdn;
    listen = [
      {
        addr = "127.0.0.1";
        port = 9444;
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
