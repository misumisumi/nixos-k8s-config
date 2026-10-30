# Headroom ダッシュボードの WG 公開用 nginx リバースプロキシ。
# listen 先は litellm/nginx.nix の Admin UI と同じ WireGuard アドレス。
# ファイアウォールの許可ポート (8787) は network.nix の interfaces.wg0 で設定する。
{
  static,
  group,
  hostname,
  lib,
  ...
}:
let
  wg = static.${group}.${hostname}.wireguard;
  dashboardAddress = lib.removeNetmask wg.serverAddress;
in
{
  services.nginx.virtualHosts."headroom-wg" = {
    serverName = "headroom-wg";
    listen = [
      {
        addr = dashboardAddress;
        port = 8787;
      }
    ];

    locations."/" = {
      proxyPass = "http://127.0.0.1:8787";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_buffering off;
        proxy_read_timeout 600s;
        proxy_send_timeout 600s;
      '';
    };

    extraConfig = ''
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
    '';
  };
}