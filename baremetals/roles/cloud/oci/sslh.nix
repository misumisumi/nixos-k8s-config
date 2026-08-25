{
  # sslh: UDP 443 を WireGuard の入口としてデマルチプレクス。
  # wg0 は listenPort 51820 のまま、sslh が 443 で受信した WG 握手を 127.0.0.1:51820 へ転送する。
  # クライアントは endpoint を <oci-ip>:51820 と <oci-ip>:443 のどちらでも接続可能。
  services.sslh = {
    enable = true;
    # UDP デマルチプレクスは fork 方式では動かないため ev を使用
    method = "ev";
    listenAddresses = [ "0.0.0.0" ];
    port = 443;
    settings = {
      # クライアント(addr:port)↔バックエンドの対応を長めに保持（再プローブによる
      # 非握手 WG パケットの誤転送を回避）。WG 再握手は 120s 周期なので 180s で余裕。
      listen = [
        {
          host = "0.0.0.0";
          is_udp = true;
          port = "443";
        }
      ];
      protocols = [
        {
          name = "ssh";
          service = "ssh";
          host = "localhost";
          port = "22";
          keepalive = true;
          tfo_ok = true;
        }
        {
          name = "tls";
          host = "localhost";
          port = "9443";
          tfo_ok = true;
        }
        {
          name = "wireguard";
          host = "localhost";
          port = "51820";
          is_udp = true;
        }
      ];
    };
  };
}
