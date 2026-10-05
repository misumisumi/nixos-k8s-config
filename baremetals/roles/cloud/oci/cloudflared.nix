# Cloudflare Tunnel (locally-managed) のコネクタ設定。
# トンネル・DNS・Access は Terraform (terraform/cloudflare) が管理し、
# ここでは static の定義に従って credentials JSON と ingress を組み立てる。
{
  config,
  lib,
  static,
  group,
  hostname,
  ...
}:
let
  tunnels = static.${group}.${hostname}.cloudflared.tunnels;
  tunnelNames = builtins.attrNames tunnels;
  tfSopsFile = ../../../../terraform/cloudflare/branch/production.yaml;
in
{
  sops.secrets = {
    # AccountTag (Account ID) は全トンネル共通
    "cloudflare/account_id" = {
      sopsFile = tfSopsFile;
    };
  }
  // lib.listToAttrs (
    map (name: {
      name = "cloudflared/tunnels/${name}/secret";
      value = {
        sopsFile = tfSopsFile;
      };
    }) tunnelNames
  );

  # ローカル管理用の credentials JSON を sops の値から組み立てる
  sops.templates = lib.listToAttrs (
    map (name: {
      name = "cloudflared/${name}/credentials.json";
      value.content = builtins.toJSON {
        AccountTag = config.sops.placeholder."cloudflare/account_id";
        TunnelID = tunnels.${name}.id;
        TunnelSecret = config.sops.placeholder."cloudflared/tunnels/${name}/secret";
      };
    }) tunnelNames
  );

  services.cloudflared = {
    enable = true;
    # attr 名は cloudflared の `tunnel:` に使われるためトンネル UUID にする
    tunnels = lib.listToAttrs (
      map (name: {
        name = tunnels.${name}.id;
        value = {
          credentialsFile = config.sops.templates."cloudflared/${name}/credentials.json".path;
          default = "http_status:404";
          ingress = lib.mapAttrs (fqdn: service: {
            inherit service;
            originRequest.originServerName = fqdn;
          }) tunnels.${name}.ingress;
        };
      }) tunnelNames
    );
  };
}
