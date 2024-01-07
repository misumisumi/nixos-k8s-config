{ workspace
, ...
}:
let
  pwd = builtins.toPath (builtins.getEnv "PWD");
in
{
  deployment.keys = {
    "etcd-ca.pem" = {
      keyFile = "${pwd}/.kube/${workspace}/etcd/ca.pem";
      destDir = "/var/lib/secrets/flannel";
    };
    "etcd-client.pem" = {
      keyFile = "${pwd}/.kube/${workspace}/flannel/etcd-client.pem";
      destDir = "/var/lib/secrets/flannel";
    };
    "etcd-client-key.pem" = {
      keyFile = "${pwd}/.kube/${workspace}/flannel/etcd-client-key.pem";
      destDir = "/var/lib/secrets/flannel";
    };
  };

}
