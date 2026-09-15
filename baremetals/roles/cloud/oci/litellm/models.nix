# LiteLLM が公開するモデル一覧。
# haruna (WireGuard peer "dgx": 10.250.0.55) 上で OpenAI 互換 (/v1) として提供されている。
{
  host = "10.250.0.55";
  list = [
    {
      name = "qwen3.5-0.8b";
      port = 9000;
    }
    {
      name = "qwen3.8-27b";
      port = 9010;
    }
    {
      name = "gemma4-26b-a4b";
      port = 9020;
    }
  ];
}
