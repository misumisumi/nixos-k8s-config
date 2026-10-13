{
  static,
  hostSecretPath,
  ...
}:
let
  # hub(OCI) 情報は static から取得（dev/prod で自動切替）。
  hub = static.cloud.oci.wireguard;
  # 自ホスト(border-router) の wg アドレスは hub 側のピア定義から導出
  selfAddr = hub.peers."homelab".address;
in
{
  # WireGuard クライアント（自宅側発呼）。
  # allowedIPs = [ hub.subnet ] のみなので、自宅→インターネットは v6plus のまま OCI 非経由。
  # 外部→自宅は hub 経由で届き、返信(10.250.0.0/24 宛)だけがトンネルを通る。
  networking.wireguard.interfaces.wg0 = {
    ips = [ "${selfAddr}/24" ];
    mtu = 1280; # v6plus トンネル越え考慮
    privateKeyFile = "/var/lib/secrets/wireguard/privatekey";
    peers = [
      {
        publicKey = "BR2XCDtghHRZYqGryTPbal+Ms7gYlgzN+b+AAlWGIms=";
        presharedKeyFile = "/var/lib/secrets/wireguard/peer/oci/psk";
        allowedIPs = [ hub.subnet ];
        endpoint = "${hub.endpoint}:${toString hub.listenPort}";
        persistentKeepalive = 25;
      }
    ];
  };
}
