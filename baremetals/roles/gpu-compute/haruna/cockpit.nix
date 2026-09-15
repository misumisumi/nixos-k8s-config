{
  #NOTE: rootless podmanでGPUを使う場合 (podman=<5.1.0, nvidia-container-toolkit>=1.20.0)
  # CDI schema ver 7.0にpodmanが対応していないため、次のコマンドでCDIを生成する必要がある
  # sudo nvidia-ctk cdi generate --feature-flag no-additional-gids-for-device-nodes --output /etc/cdi/nvidia.yaml
  # ref: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/1.20.0/release-notes.html#known-issues
  #NOTE: NixOSと違ってこれらのパッケージのserviceは自動的に有効になる
  apt = {
    packages = [
      "cockpit"
      "cockpit-files"
      "cockpit-podman"
      "dockermanager"
      "pcp-zeroconf"
    ];
    pins.cockpit-backports = {
      package = "cockpit*"; # cockpit* で cockpit系一括。厳密に列挙するなら個別定義
      pin = "release a=noble-backports";
      priority = 500;
      explanation = "Prefer cockpit from noble-backports";
    };
    repos = {
      cockpit-dockermanager = {
        arch = "all";
        components = [
          "main"
        ];
        suite = "stable";
        trusted = true;
        uri = "https://chrisjbawden.github.io/cockpit-dockermanager";
      };
    };
  };
  environment.etc."cockpit/cockpit.conf".text = ''
    [WebService]
    Origins = https://localhost:9090 https://10.250.0.55:9090 https://192.168.8.211:9090
    LoginTo = false
  '';
}
