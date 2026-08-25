{
  config,
  lib,
  static,
  group,
  hostname,
  ...
}:
let
  wg = static.${group}.${hostname}.wireguard;

  # 各ピアの PSK は sops に格納（キー名: wg-peer-<name>-psk）
  peerPskSecrets = lib.mapAttrs' (name: _: lib.nameValuePair "wg-peer-${name}-psk" { }) wg.peers;
in
{
  # --- sops secrets (runtime 復号) ---
  sops.secrets = {
    "wg-server-privateKey" = { };
  }
  // peerPskSecrets;

  # --- WireGuard hub ---
  # Subnet 10.250.0.0/24（k8s の 10.100.0.0/16 とは被らない）。
  # サーバー側 allowedIPs = ピア自身の /32 + ピアが表す帯域（自宅LAN等）。
  # フルトンネル(0.0.0.0/0) はクライアント側の設定（hub 側には張らない）。
  networking = {
    firewall.extraForwardRules = "iifname wg0 accept";
    wireguard.interfaces.wg0 = {
      ips = [ wg.serverAddress ];
      mtu = 1420;
      inherit (wg) listenPort;
      privateKeyFile = config.sops.secrets."wg-server-privateKey".path;

      peers = lib.mapAttrsToList (name: p: {
        inherit (p) publicKey;
        presharedKeyFile = config.sops.secrets."wg-peer-${name}-psk".path;
        allowedIPs = [ "${p.address}/32" ] ++ p.allowedIPs;
      }) wg.peers;
    };
  };
}
