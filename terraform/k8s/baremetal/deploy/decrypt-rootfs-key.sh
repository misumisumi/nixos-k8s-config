#!/usr/bin/env bash

set -euo pipefail

mkdir -p disk_keys

PROJECT_DIR="$(git rev-parse --show-superproject-working-tree --show-toplevel | head -1)"

sops --extract '["rootfs"]' -d "$PROJECT_DIR/sops/keystore/$WORKSPACE_NAME/secrets.yaml" #>"./disk_keys/rootfs.key"
