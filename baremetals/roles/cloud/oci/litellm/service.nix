# LiteLLM 本体（OpenAI 互換ゲートウェイ）。
# DB・Admin UI は使わない構成のため、認証は Cloudflare Access (Service Token) に一本化する。
{ ... }:
let
  models = import ./models.nix;

  modelList = map (m: {
    model_name = m.name;
    litellm_params = {
      model = "openai/${m.name}";
      api_base = "http://${models.host}:${toString m.port}/v1";
      # haruna 側は無認証の OpenAI 互換サーバーのためダミー値を渡す
      api_key = "dummy";
    };
  }) models.list;
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
      litellm_settings.drop_params = true;
    };
  };

  # 漏洩時の SSRF 対策: クラウドメタデータサービスへの到達を遮断する
  systemd.services.litellm.serviceConfig.IPAddressDeny = "169.254.169.254/32";
}
