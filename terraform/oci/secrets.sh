#!/usr/bin/env bash
# nixos-anywhere --extra-files 用: ターゲットの /etc/ssh へ投入する ssh ホスト鍵を配置する。
# このリポジトリの secrets（git-crypt）を読み取るため、実行前に git-crypt を unlock すること。
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/../../baremetals/secrets/production/roles/cloud/oci/ssh"

if [ ! -f "$SRC/ssh_host_ed25519_key.pub" ]; then
  echo "ssh host key not found: $SRC (git-crypt unlocked?)" >&2
  exit 1
fi
if [ ! -f "$SRC/ssh_host_rsa_key.pub" ]; then
  echo "ssh host key not found: $SRC (git-crypt unlocked?)" >&2
  exit 1
fi

mkdir -p etc/ssh
umask 077
cp "$SRC/ssh_host_ed25519_key" etc/ssh/ssh_host_ed25519_key
cp "$SRC/ssh_host_rsa_key" etc/ssh/ssh_host_rsa_key
umask 133
cp "$SRC/ssh_host_ed25519_key.pub" etc/ssh/ssh_host_ed25519_key.pub
cp "$SRC/ssh_host_rsa_key" etc/ssh/ssh_host_rsa_key.pub

ls -l etc/ssh
