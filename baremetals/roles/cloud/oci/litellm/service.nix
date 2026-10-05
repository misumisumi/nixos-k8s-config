# LiteLLM 本体（OpenAI 互換ゲートウェイ）。
# DB・Admin UI は使わない構成のため、認証は Cloudflare Access (Service Token) に一本化する。
{ lib, ... }:
let
  inherit (lib) flatten;
  providers = import ./providers.nix;
  modelList = flatten (map (p: p.models) providers);
in
{
  services.litellm = {
    enable = true;
    host = "127.0.0.1";
    port = 4000;
    # Admin UI（DB 必須）は使わない。攻撃面を減らすため無効化。
    environment.DISABLE_ADMIN_UI = "True";
    settings = {
      model_list = modelList;
      litellm_settings = {
        drop_params = true;
        # completion の上流(haruna)への httpx read timeout は既定 600s のため、
        # thinking 中に抵触しないよう引き上げる。
        request_timeout = 3600;
        # 1.99.0 以降で有効。TTFT 中に `: ping` を送り nginx/Cloudflare の
        # idle タイムアウトを防ぐ（1.89.0 では no-op）。
        sse_keepalive_ping_interval_seconds = 15;
      };
    };
  };

  # 漏洩時の SSRF 対策: クラウドメタデータサービスへの到達を遮断する
  systemd.services.litellm.serviceConfig.IPAddressDeny = "169.254.169.254/32";
}
