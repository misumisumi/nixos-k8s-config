{ name
, workspace
, ...
}:
let
  pwd = /. + builtins.getEnv "PWD";
  mkSecret = filename: {
    keyFile = "${pwd}/.kube/${workspace}/kubernetes/apiserver/${filename}";
    destDir = "/var/lib/secrets/kubernetes/apiserver";
    user = "kubernetes";
  };
  mkServerSecret = filename: {
    keyFile = "${pwd}/.kube/${workspace}/kubernetes/apiserver/${workspace}/${filename}";
    destDir = "/var/lib/secrets/kubernetes/apiserver";
    user = "kubernetes";
  };
in
{
  imports = [
    ../../init/colmena.nix
    ../node/colmena.nix
  ];
  deployment = {
    tags = [ "k8s" "controlplane" ];
    keys = {
      # For k8s apiserver
      "server.pem" = mkServerSecret "server.pem";
      "server-key.pem" = mkServerSecret "server-key.pem";

      "kubelet-client.pem" = mkSecret "kubelet-client.pem";
      "kubelet-client-key.pem" = mkSecret "kubelet-client-key.pem";

      "api-etcd-ca.pem" = {
        keyFile = "${pwd}/.kube/${workspace}/etcd/ca.pem";
        destDir = "/var/lib/secrets/kubernetes/apiserver";
        user = "kubernetes";
      };
      "api-etcd-client.pem" = mkSecret "etcd-client.pem";
      "api-etcd-client-key.pem" = mkSecret "etcd-client-key.pem";

      # For k8s controller-manager
      "controller-manager.pem" = {
        keyFile = "${pwd}/.kube/${workspace}/kubernetes/controller-manager.pem";
        destDir = "/var/lib/secrets/kubernetes";
        user = "kubernetes";
      };
      "controller-manager-key.pem" = {
        keyFile = "${pwd}/.kube/${workspace}/kubernetes/controller-manager-key.pem";
        destDir = "/var/lib/secrets/kubernetes";
        user = "kubernetes";
      };

      # For k8s kubelet
      "ca.pem" = {
        keyFile = "${pwd}/.kube/${workspace}/kubernetes/ca.pem";
        destDir = "/var/lib/secrets/kubernetes";
        user = "kubernetes";
        permissions = "0644";
      };

      "kubelet.pem" = {
        keyFile = "${pwd}/.kube/${workspace}/kubernetes/kubelet/${name}.pem";
        destDir = "/var/lib/secrets/kubernetes";
        user = "kubernetes";
      };

      "kubelet-key.pem" = {
        keyFile = "${pwd}/.kube/${workspace}/kubernetes/kubelet/${name}-key.pem";
        destDir = "/var/lib/secrets/kubernetes";
        user = "kubernetes";
      };

      # For k8s scheduler
      "scheduler.pem" = {
        keyFile = "${pwd}/.kube/${workspace}/kubernetes/scheduler.pem";
        destDir = "/var/lib/secrets/kubernetes";
        user = "kubernetes";
      };
      "scheduler-key.pem" = {
        keyFile = "${pwd}/.kube/${workspace}/kubernetes/scheduler-key.pem";
        destDir = "/var/lib/secrets/kubernetes";
        user = "kubernetes";
      };
    };
  };
}
