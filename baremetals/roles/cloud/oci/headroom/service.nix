# Headroom sidecar (context compression service).
# litellm の headroom ガードレールから http://127.0.0.1:8787/v1/compress
# として呼び出される。公開 /v1/ は litellm のまま変更しない。
{
  virtualisation.oci-containers.containers.headroom = {
    image = "ghcr.io/headroomlabs-ai/headroom:latest";
    autoStart = true;
    extraOptions = [ "--network=host" ];
    volumes = [ "headroom-data:/home/nonroot/.headroom" ];
    environment = {
      HEADROOM_HOST = "127.0.0.1";
      HEADROOM_PORT = "8787";
      HEADROOM_RPM = "2000";
      HEADROOM_MODE = "cache";
      # Claude Code 等の user メッセージも圧縮対象にする
      # (未設定だと user/system は保護されて圧縮されない)
      HEADROOM_COMPRESS_USER_MESSAGES = "1";
      HF_HOME = "/home/nonroot/.headroom/hf";
      HEADROOM_TELEMETRY = "off";
      HEADROOM_BEACON = "off";
    };
  };

  systemd.services.podman-headroom = {
    after = [ "podman-litellm.service" "network-online.target" ];
    wants = [ "podman-litellm.service" "network-online.target" ];
  };
}
