{ workspace, ... }:
let
  pwd = builtins.toPath (builtins.getEnv "PWD");
  mkSecret = filename: {
    keyFile = "${pwd}/.kube/${workspace}/etcd" + "/${filename}";
    destDir = "/var/lib/secrets/etcd";
    user = "etcd";
  };
in
{
  deployment = {
    tags = [ "cardinal" "k8s" "etcd" ];
    keys = {
      "ca.pem" = mkSecret "ca.pem";
      "peer.pem" = mkSecret "peer.pem";
      "peer-key.pem" = mkSecret "peer-key.pem";
      "server.pem" = mkSecret "server.pem";
      "server-key.pem" = mkSecret "server-key.pem";
    };
  };
}
