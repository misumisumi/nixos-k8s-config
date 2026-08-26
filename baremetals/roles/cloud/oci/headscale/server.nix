# Headscale コントロールサーバー + 内蔵 DERP リレー。
{ config, pkgs, static, group, hostname, ... }:
let
  inherit (static.${group}.${hostname}) tailnet;
  fqdn = tailnet.host; # oci.misumi-sumi.com
  # Headscale は CGNAT レンジ外の prefix を「unsupported」と警告するため、
  # Tailscale 標準の 100.64.0.0/10 を使用する。
  prefixV4 = "100.64.0.0/10";
in
{
  sops.secrets."headscale-oidc-client-secret" = {
    # 値は dex.nix の HEADSCALE_OIDC_CLIENT_SECRET と同一にすること
    #（Dex ↔ Headscale 間の confidential client secret）。
    owner = "headscale";
    group = "headscale";
    restartUnits = [ "headscale.service" ];
  };

  # 内蔵 DERP の STUN（NAT 走査）。DERP 本体は nginx 経由の /derp で提供。
  networking.firewall.allowedUDPPorts = [ tailnet.derp.stunPort ];

  services.headscale = {
    enable = true;
    address = "127.0.0.1";
    # NOTE: 8080 は Pi-hole webserver が使用中のため 8090 を使用。
    port = 8090;

    settings = {
      server_url = "https://${fqdn}";

      prefixes = {
        v4 = prefixV4;
        v6 = "fd7a:115c:a1e0::/48";
        allocation = "sequential";
      };

      dns = {
        magic_dns = true;
        base_domain = tailnet.dnsBaseDomain;
        # クライアントの通常 DNS 解決は握らない（MagicDNS のみ提供）。
        override_local_dns = false;
        nameservers.global = [
          # Phase 移行後、Pi-hole を tailscale0 バインドに変更したら切替:
          # （sequential 割当の先頭。OCI の tailscale を最初に登録すればこの IP を得る）
          # "100.64.0.1"
        ];
      };

      derp = {
        # 自己完結構成。公式 DERP をフォールバックに使う場合は
        # "https://controlplane.tailscale.com/derpmap/default" を追加。
        urls = [ ];
        auto_update_enabled = false;
        server = {
          enabled = true;
          region_id = tailnet.derp.regionId;
          region_code = "oci";
          region_name = "OCI";
          stun_listen_addr = "0.0.0.0:${toString tailnet.derp.stunPort}";
          # tailnet 登録済みノードのみリレー利用可
          verify_clients = true;
        };
      };

      database = {
        type = "sqlite";
        sqlite.write_ahead_log = true;
      };

      policy = {
        mode = "file";
        path = pkgs.writeText "headscale-policy.hujson" (builtins.readFile ./policy.hujson);
      };

      # 認証: Dex 経由で GitHub OAuth。ユーザーは初回ログイン時に自動作成。
      oidc = {
        issuer = "https://${fqdn}/dex";
        client_id = "headscale";
        client_secret_path = config.sops.secrets."headscale-oidc-client-secret".path;
        scope = [ "openid" "profile" "email" ];
        # GitHub の noreply mail もあり得るためドメイン制限はしない
        allowed_domains = [ ];
        allowed_users = [ ];
      };
    };
  };
}
