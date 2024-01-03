{ workspace, ... }:
let
  # TODO: DEPRECATED! Use /. + "/path"
  pwd = builtins.toPath (builtins.getEnv "PWD");
in
{
  deployment = {
    tags = [ "cardinal" "k8s" "controlplane" ];
    keys."ca.pem" = {
      keyFile = "${pwd}/.kube/${workspace}/kubernetes/ca.pem";
      destDir = "/var/lib/secrets/kubernetes";
      user = "kubernetes";
    };
  };
}
