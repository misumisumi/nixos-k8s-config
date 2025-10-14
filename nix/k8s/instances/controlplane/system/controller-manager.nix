{ lib
, virtualIP
, ...
}:
{
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
    rootCaFile = "/var/lib/secrets/kubernetes/ca.pem";
  };
}
