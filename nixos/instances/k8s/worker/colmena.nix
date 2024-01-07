{ name
, workspace
, ...
}:
let
  # TODO: DEPRECATED! Use /. + "/path"
  pwd = builtins.toPath (builtins.getEnv "PWD");
in
{
  imports = [
    ../../init/colmena.nix
    ../node/colmena.nix
  ];
  deployment = {
    tags = [ "cardinal" "k8s" "worker" ];
    keys = {
      "ca.pem" = {
        keyFile = "${pwd}/.kube/${workspace}/kubernetes/ca.pem";
        destDir = "/var/lib/secrets/kubernetes";
        user = "kubernetes";
        permissions = "0644";
      };

      "kubelet.pem" = {
        keyFile = "${pwd}/.kube/${workspace}/kubernetes/kubelet" + "/${name}.pem";
        destDir = "/var/lib/secrets/kubernetes";
        user = "kubernetes";
      };

      "kubelet-key.pem" = {
        keyFile = "${pwd}/.kube/${workspace}/kubernetes/kubelet" + "/${name}-key.pem";
        destDir = "/var/lib/secrets/kubernetes";
        user = "kubernetes";
      };
    };
  };
}
