# LiteLLM が公開するモデル一覧。
# haruna (WireGuard peer "dgx": 10.250.0.55) 上で OpenAI 互換 (/v1) として提供されている。
[
  (
    let
      host = "10.250.0.55";
      api_key = "dummy";
    in
    {
      models = [
        {
          model_name = "qwen3.8-flash-next";
          litellm_params = {
            inherit api_key;
            model = "openai/qwen3.8-flash-next";
            api_base = "http://${host}:9010/v1";
            allowed_openai_params = [ "reasoning_effort" ];
          };
          model_info = {
            supports_reasoning = true;
            reasoning_effort_levels = [
              "low"
              "medium"
              "xhigh"
            ];
          };
        }
        {
          model_name = "gemma4-26b-a4b-it";
          litellm_params = {
            inherit api_key;
            model = "openai/gemma4-26b-a4b-it";
            api_base = "http://${host}:9020/v1";
          };
        }
      ];
    }
  )
]
