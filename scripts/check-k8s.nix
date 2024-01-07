{ writeShellApplication }:
writeShellApplication {
  name = "check-k8s";
  text = ''
    set -e

    etcd1_ip=$(jq -r '.values.root_module.child_modules[] | .resources[] | select(.values.id == "etcd1").values.ip_address' show.json)

    etcdctl --endpoints "https://''${etcd1_ip}:2379" \
      --cacert=./.kube/etcd/ca.pem \
      --cert=./.kube/etcd/peer.pem \
      --key=./.kube/etcd/peer-key.pem \
      -w table endpoint status

    k --request-timeout 1 cluster-info

    k run --rm --attach --restart Never \
      --image busybox \
      busybox \
      --command id | tee /dev/stderr | grep -q "uid=0(root) gid=0(root) groups=0(root),10(wheel)" && echo "Pass"

    k run --rm --attach --restart Never \
      --image busybox \
      busybox \
      --command nslookup kubernetes | tee /dev/stderr | grep -q "Address: 10.32.0.1" && echo "Success"
  '';
}
