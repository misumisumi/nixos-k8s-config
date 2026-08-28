{
  lib,
  writeShellScriptBin,
  sops,
  wireguard-tools,
  qrencode,
  yq,
  ...
}:
let
  inherit (lib) getExe;
in
{
  wg-peer = writeShellScriptBin "wg-peer" ''
    set -euo pipefail

    SOPS=${getExe sops}
    WG=${getExe wireguard-tools}
    QRENCODE=${getExe qrencode}
    YQ=${getExe yq}

    # ---- defaults ----
    NAME=''${WG_NAME:-oci}
    ADDRESS=''${WG_ADDRESS:-10.250.0.254/24}
    DNS=''${WG_DNS:-10.250.0.1}
    MTU=''${WG_MTU:-1280}
    ALLOWED_IPS=''${WG_ALLOWED_IPS:-10.250.0.0/24}
    ENDPOINT=''${WG_ENDPOINT:-oci.misumi-sumi.com:443}
    KEEPALIVE=''${WG_KEEPALIVE:-10}

    PROJECT_ROOT="''${FLAKE_ROOT:-$PWD}"
    SECRETS_FILE="$PROJECT_ROOT/baremetals/secrets/production/roles/cloud/$NAME/secrets.yaml"

    decrypt() {
      $SOPS -d "$SECRETS_FILE"
    }

    build_conf() {
      local key="$1" peer_priv="$2" server_pub="$3" psk="$4"
      printf '[Interface]\nName = %s\nPrivateKey = %s\nAddress = %s\nDNS = %s\nMTU = %s\n\n[Peer]\nPublicKey = %s\nPresharedKey = %s\nAllowedIPs = %s\nEndpoint = %s\nPersistentKeepalive = %s\n' \
        "$NAME" "$peer_priv" "$ADDRESS" "$DNS" "$MTU" \
        "$server_pub" "$psk" "$ALLOWED_IPS" "$ENDPOINT" "$KEEPALIVE"
    }

    cmd="''${1:-}"
    case "$cmd" in
      list)
        decrypt | $YQ -r '.wireguard.peers | keys[]'
        ;;
      qr)
        [ $# -lt 2 ] && { echo "usage: wg-peer qr <key>"; exit 1; }
        key="$2"
        tmp=$(mktemp)
        decrypt > "$tmp"
        peer_priv=$($YQ -r ".wireguard.peers.\"$key\".privatekey" "$tmp")
        psk=$($YQ -r ".wireguard.peers.\"$key\".psk" "$tmp")
        server_pub=$($YQ -r '.wireguard.publicKey' "$tmp")
        rm -f "$tmp"
        build_conf "$key" "$peer_priv" "$server_pub" "$psk" | $QRENCODE -t PNG -o "wg-$key.png"
        echo "written wg-$key.png"
        ;;
      conf)
        [ $# -lt 2 ] && { echo "usage: wg-peer conf <key>"; exit 1; }
        key="$2"
        tmp=$(mktemp)
        decrypt > "$tmp"
        peer_priv=$($YQ -r ".wireguard.peers.\"$key\".privatekey" "$tmp")
        psk=$($YQ -r ".wireguard.peers.\"$key\".psk" "$tmp")
        server_pub=$($YQ -r '.wireguard.publicKey' "$tmp")
        rm -f "$tmp"
        build_conf "$key" "$peer_priv" "$server_pub" "$psk" > "wg-$key.conf"
        echo "written wg-$key.conf"
        ;;
      add)
        priv=$($WG genkey)
        pub=$(echo "$priv" | $WG pubkey)
        psk=$($WG genpsk)
        echo "PublicKey:     $pub"
        echo "PrivateKey:    $priv"
        echo "PresharedKey:  $psk"
        ;;
      *)
        echo "usage: wg-peer <list|qr|conf|add> [key]"
        exit 1
        ;;
    esac
  '';
}
