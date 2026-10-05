# Paseo relay: ゼロ知識 WebSocket relay。
#
# relay 本体は loopback（127.0.0.1）でしか listen せず、外部への公開は
# Cloudflare Tunnel（static.nix の cloudflared.tunnels.relay）が担う。
# daemon も client も relay へ外向きに接続するため、OCI の inbound 公開は不要。
# relay はペイロードを読めない（E2EE）ので open relay として運用する。
#
# 待受ポートは static.nix の `paseo.relay.port` を cloudflared の ingress と
# 共有する（同一ホストの litellm が 4000 を使っているため 4001）。
{
  lib,
  pkgs,
  config,
  static,
  group,
  hostname,
  ...
}:
let
  user = "paseo-relay";
  stateDir = "/var/lib/${user}";

  # Config.ex の PASEO_RELAY_HOST は IP アドレスのみ受理する（ホスト名不可）。
  # 公開 IF には listen しないこと。
  relayHost = "127.0.0.1";
  port = static.${group}.${hostname}.paseo.relay.port;
  relayCookie = config.sops.placeholder."${user}/cookie";

in
{
  users.users.${user} = {
    isSystemUser = true;
    group = user;
    description = "Paseo relay service";
  };
  users.groups.${user} = { };

  # Elixir リリースの起動スクリプトは cookie を必ず読み込むが、nixpkgs の
  # mixRelease は releases/COOKIE を出力に含めない（read-only な store にも
  # 書けない）。未設定だと起動スクリプトが cat で失敗してサービスが上がらない。
  # したがって sops の cookie を env ファイルに描いて EnvironmentFile で渡す。
  #
  # attrpath 分割（`"${user}/env".owner` を 2 回書く）は動的 attr の重複定義で
  # 弾かれるため、素直に attrset にする。
  sops = {
    secrets."${user}/cookie" = {
      owner = user;
      group = user;
    };
    templates."${user}/env" = {
      owner = user;
      group = user;
      content = "RELEASE_COOKIE=${relayCookie}\n";
    };
  };

  systemd.services.${user} = {
    description = "Paseo relay (zero-knowledge WebSocket relay)";
    documentation = [ "https://github.com/getpaseo/paseo-relay" ];
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      # リリースの wrapper は `start` サブコマンドを要求する。付けないと
      # usage を吐いて exit 0 になり、Restart=on-failure も発動しない
      # （systemd 上は active だが relay が居ない状態になる）。
      ExecStart = "${lib.getExe pkgs.paseo-relay} start";
      # config/runtime.exs は BEAM 起動時に読むため、EnvironmentFile の
      # RELEASE_COOKIE も他の環境変数と同時に渡る。
      EnvironmentFile = config.sops.templates."${user}/env".path;
      Environment = [
        "PASEO_RELAY_HOST=${relayHost}"
        "PASEO_RELAY_PORT=${toString port}"
        # 新規接続の admission を止める状態（既定 false のまま運用する）。
        # drain は状態変数であり、HTTP で操作する手段は無い。
        "PASEO_RELAY_DRAIN=false"
        # Elixir リリースは起動時に writable な HOME を参照しうるため、
        # StateDirectory 之下を HOME にする。ログは stdout のみ。
        "HOME=${stateDir}"
        # systemd にはロケールが渡らないため latin1 扱いになり、
        # 「expected utf8」警告が出る。+fnu で UTF-8 に固定する。
        "ELIXIR_ERL_OPTIONS=+fnu"
      ];
      User = user;
      Group = user;

      # 書き込み可能なのは StateDirectory のみ（read-only な /nix/store を含む）。
      StateDirectory = user;
      Restart = "on-failure";
      # クライアント再接続サージと重ならないよう余裕を持たせる。
      RestartSec = "15s";
      # SIGTERM で新規接続を受け入れず既存接続の終了を待つ。
      KillSignal = "SIGTERM";
      TimeoutStopSec = "30s";

      # 攻撃面の絞り込み
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;

      # OCI のメタデータサービス（cloud metadata）への到達を遮断する。
      # litellm と同じ方針（漏洩時の到達経路を塞ぐ）。
      IPAddressDeny = "169.254.169.254/32";
    };
  };
}
