# nginx リバースプロキシ。
# - 公開: Cloudflare Tunnel からのみ /v1 (OpenAI 互換 API) を公開。
# - WG のみ: Admin UI (webui) を WireGuard アドレスで公開。
{
  static,
  group,
  hostname,
  lib,
  pkgs,
  ...
}:
let
  inherit (static.${group}.${hostname}) litellm;
  wg = static.${group}.${hostname}.wireguard;
  dashboardAddress = lib.removeNetmask wg.serverAddress;

  waitForWgAddress = pkgs.writeShellApplication {
    name = "wait-for-litellm-wg-address";
    runtimeInputs = [ pkgs.iproute2 ];
    text = ''
      for _ in $(seq 1 60); do
        if ip -4 addr show dev wg0 | grep -qF '${dashboardAddress}/'; then
          exit 0
        fi
        sleep 1
      done
      echo "wg0 address ${dashboardAddress} did not appear" >&2
      exit 1
    '';
  };
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

  # LiteLLM の OpenAI Model Discovery 用パス書き換えプロキシ。
  # LiteLLM の OpenAI discovery は api_base のパスを捨てて `{host}/v1/models` を
  # 叩くため、/v1/* を Command Code の Provider API (/provider/v1/*) に変換する。
  # LiteLLM コンテナは --network=host なので 127.0.0.1 で到達できる。
  # ホスト外 (Cloudflare Tunnel 等) からは到達不可。
  services.nginx.virtualHosts."commandcode" = {
    serverName = "commandcode";
    listen = [
      {
        addr = "127.0.0.1";
        port = 18080;
      }
    ];

    locations = {
      # Claude 系は Anthropic Messages 形式。/v1/messages だけは LiteLLM が
      # `x-api-key` で認証するため、Command Code が要求する Bearer に変換する。
      "/v1/messages" = {
        proxyPass = "https://api.commandcode.ai/provider/v1/messages";
        extraConfig = ''
          proxy_ssl_server_name on;
          proxy_ssl_verify on;
          proxy_ssl_trusted_certificate ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt;

          proxy_http_version 1.1;
          proxy_set_header Host api.commandcode.ai;
          proxy_set_header Connection "";
          proxy_set_header Authorization "Bearer $http_x_api_key";

          proxy_pass_request_headers on;

          proxy_buffering off;
          proxy_request_buffering off;
          proxy_read_timeout 600s;
          proxy_send_timeout 600s;
        '';
      };
      "/v1/" = {
        proxyPass = "https://api.commandcode.ai/provider/v1/";
        extraConfig = ''
          proxy_ssl_server_name on;
          proxy_ssl_verify on;
          proxy_ssl_trusted_certificate ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt;

          proxy_http_version 1.1;
          proxy_set_header Host api.commandcode.ai;
          proxy_set_header Connection "";

          # LiteLLM が送る Authorization: Bearer <COMMANDCODE_API_KEY> をそのまま転送する
          proxy_pass_request_headers on;

          proxy_buffering off;
          proxy_request_buffering off;
          proxy_read_timeout 600s;
          proxy_send_timeout 600s;
        '';
      };
      "/" = {
        return = "403";
      };
    };
  };

  # WireGuard 経由でのみアクセス可能な Admin UI (webui)
  services.nginx.virtualHosts."litellm-wg" = {
    serverName = "litellm-wg";
    listen = [
      {
        addr = dashboardAddress;
        port = 4000;
      }
    ];

    locations."/" = {
      proxyPass = "http://127.0.0.1:4000";
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

  systemd.services.nginx = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      ExecStartPre = lib.mkAfter [ "${waitForWgAddress}/bin/wait-for-litellm-wg-address" ];
      # `ip` (netlink) を ExecStartPre で使うため AF_NETLINK を許可する
      RestrictAddressFamilies = lib.mkForce [
        "AF_INET"
        "AF_INET6"
        "AF_UNIX"
        "AF_NETLINK"
      ];
    };
  };
}
