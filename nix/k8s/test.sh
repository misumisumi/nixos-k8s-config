nix run .#k-dev -- create secret generic -n kube-system cilium-etcd-secrets \
  --from-file=etcd-client-ca.crt=./secrets/develop/pki/RootCA/ca.pem \
  --from-file=etcd-client.key=./secrets/develop/pki/etcd/apiserver-etcd-client-key.pem \
  --from-file=etcd-client.crt=./secrets/develop/pki/etcd/apiserver-etcd-client-chain.pem #\
  # --dry-run=client -o yaml
