nixos-anywhere --flake ".#dev1" \
  --option pure-eval false \
  --extra-files ../../.secrets/dev1/ \
  --disk-encryption-keys /tmp/keystore.key ../../.keystore/devnode/keystore.key \
  --disk-encryption-keys /tmp/rootfs.key ../../.keystore/devnode/rootfs.key \
  --disk-encryption-keys /tmp/nfs.key ../../.keystore/additional/nfs.key \
  --disk-encryption-keys /tmp/ceph.key ../../.keystore/additional/ceph.key \
  root@192.168.101.4
