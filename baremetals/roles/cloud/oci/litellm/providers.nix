# LiteLLM が公開するモデル一覧 (model_list) と fallbacks。
#
# 役割:
#   - OmniRoute (combo.json) の combo を LiteLLM の model_name グループとして公開する
#   - `auto` (complexity_router) の tier からそれらの model_name を参照する
#   - combo の `strategy: priority` に合わせ、1 件目を本体、2 件目以降を
#     fallback 用の別名 (`<combo>-2`, `<combo>-3`, ...) として定義し、
#     litellm_settings.fallbacks で順に落ちるようにする
#
# 出力 (import 結果):
#   { models = [ ... ]; fallbacks = [ ... ]; }
#
# service.nix から `providers = import ./providers.nix;` で読み込まれる。
let
  # ============================================================
  # 1. provider ごとの共通パラメータ (api_base / api_key など)
  # ============================================================

  # Command Code は nginx (127.0.0.1:18080) が /v1/* を /provider/v1/* に rewrite する。
  commandcode = {
    api_base = "http://127.0.0.1:18080/v1";
    api_key = "os.environ/COMMANDCODE_API_KEY";
  };

  # Claude は /v1/messages 専用。LiteLLM は {api_base}/v1/messages を叩くので
  # ホスト部分だけ指定する (nginx が /provider/v1/messages に rewrite)。
  commandcodeAnthropic = {
    api_base = "http://127.0.0.1:18080";
    api_key = "os.environ/COMMANDCODE_API_KEY";
  };

  opencodeGo = {
    api_key = "os.environ/OPENCODE_API_KEY";
  };

  localllm = {
    api_key = "dummy";
  };

  # ローカル LLM (haruna / WireGuard peer "dgx": 10.250.0.55)。
  localQwen = localllm // {
    model = "openai/qwen3.8-flash-next";
    api_base = "http://10.250.0.55:9010/v1";
  };
  localGemma = localllm // {
    model = "openai/gemma4-26b-a4b-it";
    api_base = "http://10.250.0.55:9020/v1";
  };

  # ============================================================
  # 2. combo 定義 (OmniRoute combo の LiteLLM 版)
  #    並び順 = 優先順位 (priority)。1 件目が本体、以降が fallback。
  # ============================================================
  combos = {
    # commandcode → opencode_go → ローカル の順に落ちる
    quick = [
      (opencodeGo // { model = "opencode_go/beam-free"; })
      (commandcode // { model = "reflection/beam:free"; })
      (opencodeGo // { model = "opencode_go/deepseek-v4.1-flash"; })
      localGemma
    ];
    coding = [
      (opencodeGo // { model = "opencode_go/deepseek-v4.1-flash"; })
      (opencodeGo // { model = "commandcode/deepseek-v4.1-flash"; })
      localQwen
    ];
    complex = [
      (
        opencodeGo
        // {
          model = "opencode_go/gpt-6-luna";
          reasoning_effort = "max";
        }
      )
      (
        commandcode
        // {
          model = "gpt-6-luna";
          reasoning_effort = "max";
        }
      )
      localQwen
    ];
    superbrain = [
      (
        commandcodeAnthropic
        // {
          model = "claude-haiku-5-5";
          reasoning_effort = "max";
        }
      )
      (
        opencodeGo
        // {
          model = "opencode_go/claude-haiku-5-5";
          reasoning_effort = "max";
        }
      )
      localQwen
    ];

    ultrabrain = [
      (
        commandcodeAnthropic
        // {
          model = "claude-sonnet-5-5";
          reasoning_effort = "max";
        }
      )
      (
        opencodeGo
        // {
          model = "moonshotai/Kimi-K3.1-Pro";
          reasoning_effort = "max";
        }
      )
      localQwen
    ];
    reviewer = [
      (
        commandcode
        // {
          model = "gpt-5.6-sol";
          reasoning_effort = "high";
        }
      )
      (
        commandcode
        // {
          model = "zai-org/GLM-5.3";
          reasoning_effort = "high";
        }
      )
      localQwen
    ];

    writing = [
      (opencodeGo // { model = "opencode_go/deepseek-v4.1-flash"; })
      localGemma
    ];
  };

  comboNames = builtins.attrNames combos; # ソート済み (agent, coding, complex, ...)

  # ============================================================
  # 3. Command Code モデルの明示列挙
  #    wildcard (`commandcode/*`) は使わない。LiteLLM の wildcard discovery は
  #    カタログIDの先頭セグメントが provider 名 (deepseek, meta, xai, ...) だと
  #    それを削って /v1/models に出すため、一覧の名前で呼ぶと upstream が 400 になる。
  #    combo で使うモデル + kimi / beam / claude / gpt / glm を、
  #    https://commandcode.ai/docs/plans/goat の GOAT 対象に絞って明示する。
  # ============================================================

  # OpenAI 互換 (commandcode プロキシ経由)。model_name = "commandcode/<id>"
  commandcodeOpenAI = [
    "deepseek/deepseek-v4-flash"
    # combo で使用 (main-agent / quick)
    "zai-org/GLM-5.2"
    "reflection/beam:free"
    # kimi (GOAT: K3.1 Pro $20, K3 $20, K2.7 Code $60)
    "moonshotai/Kimi-K3.1-Pro"
    "moonshotai/Kimi-K3"
    "moonshotai/Kimi-K2.7-Code"
    # gpt (GOAT: GPT-6 Luna, GPT-5.6 Sol, GPT-5.6 Luna)
    "gpt-6-luna"
    "gpt-5.6-sol"
    "gpt-5.6-luna"
    # glm (GOAT: GLM-5.3 Flash, GLM-5.3 FlashX, GLM-5.3)
    "z-ai/glm-5.3-flash"
    "z-ai/glm-5.3-flashx"
    "zai-org/GLM-5.3"
  ];

  # Claude は /v1/messages 専用なので anthropic 形式で登録する。
  # GOAT で使えるのは Sonnet 5.5 ($10) と Haiku 5.5 ($20) のみ。
  commandcodeClaude = [
    "claude-sonnet-5-5"
    "claude-haiku-5-5"
  ];

  # Command Code の /v1/models は max_output_tokens を実際より大きく広報する。
  # (例: GLM-5.2 は 1M 広報だが上流の実上限は 131072)
  # discovery 値より model_info を優先させ、/v1/models の広告値を補正する。
  commandcodeModelInfo = {
    "zai-org/GLM-5.2" = {
      max_output_tokens = 131072;
    };
    "z-ai/glm-5.3-flashx" = {
      max_output_tokens = 131072;
    };
    "deepseek/deepseek-v4-flash" = {
      max_output_tokens = 393216;
    };
    "reflection/beam:free" = {
      max_output_tokens = 131072;
    };
  };

  # 上記リストから deployment エントリを生成する。
  #   model_name  = "commandcode/<id>"
  #   upstream    = "openai/<id>" または "anthropic/<id>"
  commandcodeDeployments =
    builtins.map (id: {
      model_name = "commandcode/${id}";
      litellm_params = commandcode // {
        model = "openai/${id}";
      };
      model_info = commandcodeModelInfo.${id} or { };
    }) commandcodeOpenAI
    ++ builtins.map (id: {
      model_name = "commandcode/${id}";
      litellm_params = commandcodeAnthropic // {
        model = "anthropic/${id}";
      };
    }) commandcodeClaude;

  # ============================================================
  # 4. combo → deployment 生成 (本体 + fallback 別名)
  #    i=0 : model_name = combo 名 (本体)
  #    i>=1: model_name = "<combo>-(i+1)" (fallback 先)
  # ============================================================
  comboDeployments = builtins.concatLists (
    builtins.map (
      name:
      builtins.genList (i: {
        model_name = if i == 0 then name else "${name}-${toString (i + 1)}";
        litellm_params = builtins.elemAt combos.${name} i;
      }) (builtins.length combos.${name})
    ) comboNames
  );

  # combo 名 → 2 件目以降 (fallback 先) の model_name リスト。
  # 例: quick = ["quick-2", "quick-3", "quick-4"]
  comboFallbacks = builtins.map (name: {
    ${name} = builtins.genList (i: "${name}-${toString (i + 2)}") (builtins.length combos.${name} - 1);
  }) comboNames;
in
{
  # ============================================================
  # model_list (LiteLLM が公開するモデル)
  # ============================================================
  models = [
    # --- ローカルモデル (haruna / WireGuard peer "dgx": 10.250.0.55) ---
    {
      model_name = "qwen3.8-flash-next";
      litellm_params = localQwen // {
        allowed_openai_params = [ "reasoning_effort" ];
      };
      model_info = {
        max_input_tokens = 1048576;
        max_output_tokens = 131072;
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
      litellm_params = localGemma;
      model_info = {
        max_input_tokens = 262144;
        max_output_tokens = 131072;
        supports_reasoning = true;
      };
    }

    # --- GLM-5.2: commandcode → opencode_go → ローカル の fallback 用に個別公開 ---
    {
      model_name = "glm-5.2";
      litellm_params = commandcode // {
        model = "openai/zai-org/GLM-5.2";
      };
      model_info = commandcodeModelInfo."zai-org/GLM-5.2";
    }
    {
      model_name = "glm-5.2-opencode";
      litellm_params = opencodeGo // {
        model = "opencode_go/glm-5.2";
      };
    }

    # --- opencode-go: wildcard で Model Discovery ---
    {
      model_name = "opencode_go/*";
      litellm_params = {
        model = "opencode_go/*";
        api_key = "os.environ/OPENCODE_API_KEY";
      };
    }

    # --- JEV classifier (OpenCode Console の System One) ---
    # opensource_classifier_config.deployment_name から参照する。
    # 失敗時は fallbacks で Command Code 側の JEV に落ちる。
    {
      model_name = "jev-1.13-free";
      litellm_params = {
        model = "typesafe/jev-1.13-free";
        api_base = "https://opencode.ai/inference/systemone";
        api_key = "os.environ/OPENCODE_API_KEY";
      };
    }
    # Command Code の JEV は upstream の body で `model: typesafe/jev` を要求するため、
    # provider prefix を除いた model 名が `typesafe/jev` になるよう二重に付ける。
    {
      model_name = "jev-commandcode";
      litellm_params = {
        model = "typesafe/typesafe/jev";
        api_base = "https://api.commandcode.ai/provider";
        api_key = "os.environ/COMMANDCODE_API_KEY";
      };
    }

    # --- Auto Router (complexity_router) ---
    # combo を能力順に tier へ割り当てる。SIMPLE/MEDIUM/COMPLEX/REASONING の
    # 4 tier に収まらない writing / vision はグループ単体で公開する。
    {
      model_name = "auto";
      litellm_params = {
        model = "auto_router/complexity_router";
        complexity_router_default_model = "main-agent";
        complexity_router_config = {
          tiers = {
            SIMPLE = "quick";
            MEDIUM = "codding";
            COMPLEX = "complex";
            REASONING = "superbrain";
          };
          classifier_type = "oss_classifier";
          classification_mode = "user_turn"; # 必須：tool 継続 turn で再分類させない
          enable_context_window_escalation = true;
          modality_routing = true; # 必須：画像 turn を text-only tier から逃がす
          opensource_classifier_config = {
            deployment_name = "jev-1.13-free";
            timeout_ms = 3000;
            circuit_breaker_enabled = true;
            circuit_breaker_cooldown_seconds = 30;
          };
          classifier_fallback = "heuristic";
        };
      };
    }
  ]
  ++ commandcodeDeployments
  ++ comboDeployments;

  # ============================================================
  # fallbacks (litellm_settings.fallbacks)
  # ============================================================
  fallbacks = comboFallbacks ++ [
    # GLM-5.2 単体名でも commandcode → opencode_go に落とす
    { "glm-5.2" = [ "glm-5.2-opencode" ]; }
    # Auto Router の JEV classifier フォールバック
    { "jev-1.13-free" = [ "jev-commandcode" ]; }
  ];
}
