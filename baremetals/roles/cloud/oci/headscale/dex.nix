# Dex: GitHub OAuth2 を OIDC にブリッジする IdP。
# Headscale は GitHub を直接 OIDC にできない（Discovery 非対応）ため、
# Dex を挟んで GitHub 認証を実現する。
#
#   tailscale up → Headscale → Dex → GitHub ログイン → OIDC token → 登録
{
  config,
  static,
  group,
  hostname,
  ...
}:
let
  inherit (static.${group}.${hostname}) tailnet;
  dexPort = 5556;
in
{
  # secrets.yaml の "dex-env" キーに以下を定義する:
  #   GITHUB_CLIENT_ID=<GitHub OAuth App の Client ID>
  #   GITHUB_CLIENT_SECRET=<GitHub OAuth App の Client Secret>
  #   HEADSCALE_OIDC_CLIENT_SECRET=<openssl rand -hex 32>
  sops.secrets."dex-env" = { };

  services.dex = {
    enable = true;
    environmentFile = config.sops.secrets."dex-env".path;

    settings = {
      # パス prefix 配信（nginx の /dex/ → :5556/）
      issuer = "https://${tailnet.host}/dex";
      web.http = "127.0.0.1:${toString dexPort}";

      storage = {
        type = "sqlite3";
        config.dbFile = "/var/lib/dex/dex.db";
      };

      # 承認画面は省略（個人利用）
      oauth2.skipApprovalScreen = true;
      enablePasswordDB = false;

      staticClients = [
        {
          id = "headscale";
          name = "Headscale";
          redirectURIs = [ "https://${tailnet.host}/oidc/callback" ];
          secretEnv = "HEADSCALE_OIDC_CLIENT_SECRET";
        }
      ];

      connectors = [
        {
          type = "github";
          id = "github";
          name = "GitHub";
          config = {
            clientID = "$GITHUB_CLIENT_ID";
            clientSecret = "$GITHUB_CLIENT_SECRET";
            redirectURI = "https://${tailnet.host}/dex/callback";
            orgs = [ { name = "misumi-homelab"; } ];
          };
        }
      ];
    };
  };
}
