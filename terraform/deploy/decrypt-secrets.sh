#!/usr/bin/env bash

mkdir -p "etc/ssh" "etc/secrets/initrd" ".keystore"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

umask 0177
sops --extract '["initrd"]["ssh_host_ed25519_key"]' -d "${SCRIPT_DIR}/../../sops/hosts/$WORKSPACE_NAME/$HOST_NAME/secrets.yaml" >./etc/secrets/initrd/ssh_host_ed25519_key
sops --extract '["initrd"]["ssh_host_ed25519_key.pub"]' -d "${SCRIPT_DIR}/../../sops/hosts/$WORKSPACE_NAME/$HOST_NAME/secrets.yaml" >./etc/secrets/initrd/ssh_host_ed25519_key.pub

# restore umask
umask 0022

# ssh_host_rsa_key ssh_host_rsa_key.pub
for keyname in ssh_host_ed25519_key ssh_host_ed25519_key.pub; do
  if [[ $keyname == *.pub ]]; then
    umask 0133
  else
    umask 0177
  fi
  sops --extract '["'$keyname'"]' -d "${SCRIPT_DIR}/../../sops/hosts/$WORKSPACE_NAME/$HOST_NAME/secrets.yaml" >"./etc/ssh/$keyname"
done

umask 0177
for keyname in ceph nfs; do
  sops --extract '["'$keyname'"]' -d "${SCRIPT_DIR}/../../sops/keystore/$WORKSPACE_NAME/secrets.yaml" >"./.keystore/$keyname.key"
done

umask 0022
