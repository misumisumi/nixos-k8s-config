# Cloudflare Tunnel: 外向き接続のみで litellm を公開する。
# トンネル自体は Terraform (terraform/cloudflare) で作成し、認証情報を sops から読む。
{
  config,
  static,
  group,
  hostname,
  ...
}:
let
  inherit (static.${group}.${hostname}) litellm;
in
{
  sops.secrets = {
    "cloudflared/account_tag" = { };
    "cloudflared/tunnel_id" = { };
    "cloudflared/tunnel_secret" = { };
  };

  # cloudflared のローカル管理用 credentials JSON を sops から組み立てる
  sops.templates."cloudflared/credentials.json".content = builtins.toJSON {
    AccountTag = config.sops.placeholder."cloudflared/account_tag";
    TunnelID = config.sops.placeholder."cloudflared/tunnel_id";
    TunnelSecret = config.sops.placeholder."cloudflared/tunnel_secret";
  };

  services.cloudflared = {
    enable = true;
    tunnels.${litellm.tunnelId} = {
      credentialsFile = config.sops.templates."cloudflared/credentials.json".path;
      default = "http_status:404";
      ingress.${litellm.fqdn} = {
        service = "https://127.0.0.1:9444";
      };
      originRequest.originServerName = litellm.fqdn;
    };
  };
}
