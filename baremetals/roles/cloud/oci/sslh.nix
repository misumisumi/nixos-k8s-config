{
  # sslh: TCP/UDP 443 をデマルチプレクス。
  # TCP 443 → nginx (8443) で HTTPS を処理
  # UDP 443 → WireGuard (51820) でトンネル接続
  services.sslh = {
    enable = true;
    # UDP デマルチプレクスは fork 方式では動かないため ev を使用
    method = "ev";
    listenAddresses = [ "0.0.0.0" ];
    port = 443;
    settings = {
      # TCP と UDP の両方で 443 を listen
      listen = [
        {
          host = "0.0.0.0";
          is_udp = true;
          port = "443";
        }
      ];
      protocols = [
        {
          name = "wireguard";
          host = "127.0.0.1";
          port = "51820";
          is_udp = true;
        }
        {
          name = "tls";
          host = "127.0.0.1";
          port = "8443";
        }
      ];
    };
  };
}
