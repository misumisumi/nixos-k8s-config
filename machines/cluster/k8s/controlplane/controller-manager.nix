{
  lib,
  virtualIP,
  ...
}: let
  pwd = builtins.getEnv "PWD";
in {
  # For colmena
  deployment.keys = {
    "controller-manager.pem" = {
      keyFile = "${pwd}/certs/generated/kubernetes/controller-manager.pem";
      destDir = "/var/lib/secrets/kubernetes";
      user = "kubernetes";
    };
    "controller-manager-key.pem" = {
      keyFile = "${pwd}/certs/generated/kubernetes/controller-manager-key.pem";
      destDir = "/var/lib/secrets/kubernetes";
      user = "kubernetes";
    };
  };

  services.kubernetes.controllerManager = {
    enable = true;
    extraOpts = lib.strings.concatStringsSep " " [
      "--feature-gates=KubeletInUserNamespace=true"
    ];
    kubeconfig = {
      caFile = "/var/lib/secrets/kubernetes/ca.pem";
      certFile = "/var/lib/secrets/kubernetes/controller-manager.pem";
      keyFile = "/var/lib/secrets/kubernetes/controller-manager-key.pem";
      server = "https://${virtualIP}";
    };
  };
}