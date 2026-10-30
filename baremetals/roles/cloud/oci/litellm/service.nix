# LiteLLM 本体（OpenAI 互換ゲートウェイ）。
# 公式コンテナイメージを使用。Admin UI は WireGuard 経由でのみアクセス可能。
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  settingsFormat = pkgs.formats.yaml { };
  providers = import ./providers.nix;
  modelList = providers.models;

  configFile = settingsFormat.generate "config.yaml" {
    model_list = modelList;
    guardrails = [
      # Loop detection must see the original user text: later compression
      # guardrails rewrite the conversation before the provider call.
      {
        guardrail_name = "loop-guard";
        litellm_params = {
          guardrail = "litellm_plugin_collection.loop_guard.guardrail.LoopGuard";
          mode = "pre_call";
          default_on = true;
        };
      }
      {
        guardrail_name = "headroom-compression";
        litellm_params = {
          guardrail = "headroom";
          mode = "pre_call";
          api_base = "http://127.0.0.1:8787";
          default_on = true;
        };
      }
      {
        guardrail_name = "llm-summarizer";
        litellm_params = {
          guardrail = "litellm_plugin_collection.llm_summarizer.guardrail.LLMSummarizerGuardrail";
          mode = "pre_call";
          default_on = true;
          summary_model = "qwen3.8-flash-next";
          summary_threshold_tokens = 0;
          summary_target_tokens = 4096;
          preserve_recent_turns = 4;
        };
      }
      {
        guardrail_name = "context-budget";
        litellm_params = {
          guardrail = "litellm_plugin_collection.context_budget.guardrail.ContextBudgetGuardrail";
          mode = "pre_call";
          default_on = true;
        };
      }
      {
        guardrail_name = "compression-summary";
        litellm_params = {
          guardrail = "litellm_plugin_collection.compression_summary.guardrail.CompressionSummaryGuardrail";
          mode = "pre_call";
          default_on = true;
        };
      }
    ];
    litellm_settings = {
      drop_params = true;
      request_timeout = 3600;
      sse_keepalive_ping_interval_seconds = 15;
      check_provider_endpoint = true;
      # combo の priority 順フォールバックと JEV classifier のフォールバック
      # (providers.nix で定義)
      fallbacks = providers.fallbacks;
    };
    general_settings = {
      master_key = "os.environ/LITELLM_MASTER_KEY";
      database_url = "os.environ/DATABASE_URL";
    };
    router_settings = {
      optional_pre_call_checks = [
        "deployment_affinity"
        "prompt_caching"
      ];
      deployment_affinity_ttl_seconds = 3600;
    };
  };

  pluginSrc = inputs.litellm-plugin-collection;
in
{
  sops.secrets."litellm/env" = {
    mode = "0400";
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "litellm" ];
    ensureUsers = [
      {
        name = "litellm";
        ensureDBOwnership = true;
        ensureClauses = {
          password = "litellm";
        };
      }
    ];
    settings.listen_addresses = lib.mkForce "127.0.0.1";
  };

  virtualisation = {
    podman.enable = true;
    oci-containers = {
      backend = "podman";
      containers.litellm = {
        image = "ghcr.io/berriai/litellm:main-latest";
        autoStart = true;
        extraOptions = [ "--network=host" ];
        volumes = [
          "${configFile}:/app/config.yaml:ro"
          "${pluginSrc}:/plugins:ro"
        ];
        environment = {
          DISABLE_ADMIN_UI = "False";
          PYTHONPATH = "/plugins";
        };
        environmentFiles = [
          config.sops.secrets."litellm/env".path
        ];
        cmd = [
          "--config"
          "/app/config.yaml"
          "--port"
          "4000"
          "--host"
          "127.0.0.1"
          "--use_prisma_db_push"
        ];
      };
    };
  };

  systemd.services.podman-litellm = {
    after = [
      "postgresql.service"
      "sops-install-secrets.service"
      "nginx.service"
    ];
    wants = [
      "postgresql.service"
      "sops-install-secrets.service"
    ];
  };
}
