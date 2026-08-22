{ config, lib, static, hostSecretPath, ... }:
let
  # hub(OCI) 情報は static から取得（dev/prod で自動切替）。
  hub = static.cloud.oci.wireguard;
  # 自ホスト(border-router) の wg アドレスは hub 側のピア定義から導出
  selfAddr = hub.peers."border-router".address;
in
{
  # git-crypt 管理の鍵ファイル（build 時に store へ取り込み、/etc へ配置）
  environment.etc."wireguard/border-router.key" = {
    source = hostSecretPath + "/wireguard/privatekey";
    mode = "0400";
  };
  environment.etc."wireguard/border-router.psk" = {
    source = hostSecretPath + "/wireguard/psk";
    mode = "0400";
  };

  # WireGuard クライアント（自宅側発呼）。
  # allowedIPs = [ hub.subnet ] のみなので、自宅→インターネットは v6plus のまま OCI 非経由。
  # 外部→自宅は hub 経由で届き、返信(10.250.0.0/24 宛)だけがトンネルを通る。
  networking.wireguard.interfaces.wg0 = {
    ips = [ "${selfAddr}/24" ];
    mtu = 1280; # v6plus トンネル越え考慮
    privateKeyFile = "/etc/wireguard/border-router.key";
    peers = [
      {
        publicKey = hub.publicKey;
        presharedKeyFile = "/etc/wireguard/border-router.psk";
        allowedIPs = [ hub.subnet ];
        endpoint = "${hub.endpoint}:${toString hub.listenPort}";
        persistentKeepalive = 25;
      }
    ];
  };
}
