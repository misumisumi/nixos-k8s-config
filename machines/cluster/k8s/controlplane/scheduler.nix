{virtualIP, ...}: let
  pwd = builtins.toPath (builtins.getEnv "PWD");
in {
  # For colmena
  deployment.keys = {
    "scheduler.pem" = {
      keyFile = "${pwd}/.kube/kubernetes/scheduler.pem";
      destDir = "/var/lib/secrets/kubernetes";
      user = "kubernetes";
    };
    "scheduler-key.pem" = {
      keyFile = "${pwd}/.kube/kubernetes/scheduler-key.pem";
      destDir = "/var/lib/secrets/kubernetes";
      user = "kubernetes";
    };
  };

  services.kubernetes.scheduler = {
    enable = true;
    kubeconfig = {
      caFile = "/var/lib/secrets/kubernetes/ca.pem";
      certFile = "/var/lib/secrets/kubernetes/scheduler.pem";
      keyFile = "/var/lib/secrets/kubernetes/scheduler-key.pem";
      server = "https://${virtualIP}";
    };
  };
}