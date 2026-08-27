{
  config,
  lib,
  static,
  group,
  hostname,
  ...
}:
let
  inherit (lib)
    mapAttrs'
    mapAttrsToList
    nameValuePair
    removeNetmask
    ;

  wan = static.${group}.${hostname}.networks.wan;
  wanIF = wan.IF;

  wg = static.${group}.${hostname}.wireguard;

  # 各ピアの PSK は sops に格納（キー名: wg-peer-<name>-psk）
  peerPskSecrets = mapAttrs' (name: _: nameValuePair "wg-peer-${name}-psk" { }) wg.peers;
in
{
  # --- sops secrets (runtime 復号) ---
  sops.secrets = {
    "wg-server-privateKey" = { };
  }
  // peerPskSecrets;

  #NOTE: forward設定はheadscaleので既にされている
  networking = {
    nftables.tables."manage-web-ui" = {
      family = "inet";
      content = ''
        chain prerouting {
          type nat hook prerouting priority dstnat; policy accept;
          # トンネル発 443 のみ管理UIへ。daddr条件で「公衆網IP宛ssh-over-443(フルtunnel時)」を保護
          iifname "wg0" ip daddr ${removeNetmask wg.serverAddress} tcp dport 443 redirect to :9443
        }
      '';
    };
    nat = {
      enable = true;
      externalInterface = wanIF;
      internalInterfaces = [ "wg0" ];
    };
  };

  # --- WireGuard hub ---
  # Subnet 10.250.0.0/24（k8s の 10.100.0.0/16 とは被らない）。
  # サーバー側 allowedIPs = ピア自身の /32 + ピアが表す帯域（自宅LAN等）。
  # フルトンネル(0.0.0.0/0) はクライアント側の設定（hub 側には張らない）。
  networking = {
    firewall.extraForwardRules = "iifname wg0 accept";
    wireguard.interfaces.wg0 = {
      ips = [ wg.serverAddress ];
      mtu = 1280;
      inherit (wg) listenPort;
      privateKeyFile = config.sops.secrets."wg-server-privateKey".path;

      peers = mapAttrsToList (name: p: {
        inherit (p) publicKey;
        presharedKeyFile = config.sops.secrets."wg-peer-${name}-psk".path;
        allowedIPs = [ "${p.address}/32" ] ++ p.allowedIPs;
      }) wg.peers;
    };
  };
}
