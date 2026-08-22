{
  config,
  lib,
  static,
  group,
  hostname,
  ...
}:
let
  wg = static.${group}.${lib.trace hostname hostname}.wireguard;

  # 各ピアの PSK は sops に格納（キー名: wireguard-peer-<name>-psk）
  peerPskSecrets = lib.mapAttrs' (
    name: _: lib.nameValuePair "wireguard-peer-${name}-psk" { }
  ) wg.peers;
in
{
  # --- sops secrets (runtime 復号) ---
  sops.secrets = {
    "wireguard-server-privatekey" = { };
  }
  // peerPskSecrets;

  # --- WireGuard hub ---
  # Subnet 10.250.0.0/24（k8s の 10.100.0.0/16 とは被らない）。
  # サーバー側 allowedIPs = ピア自身の /32 + ピアが表す帯域（自宅LAN等）。
  # フルトンネル(0.0.0.0/0) はクライアント側の設定（hub 側には張らない）。
  networking.wireguard.interfaces.wg0 = {
    ips = [ wg.serverAddress ];
    listenPort = wg.listenPort;
    privateKeyFile = config.sops.secrets."wireguard-server-privatekey".path;

    peers = lib.mapAttrsToList (name: p: {
      publicKey = p.publicKey;
      presharedKeyFile = config.sops.secrets."wireguard-peer-${name}-psk".path;
      allowedIPs = [ "${p.address}/32" ] ++ p.allowedIPs;
    }) wg.peers;
  };

  # sops 鍵素材が復号されてからトンネルを張るよう順序付け
  systemd.services.wireguard-wg0.after = [ "sops-install-secrets.service" ];
}
