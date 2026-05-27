{
  lib,
  static,
  ...
}:
let
  inherit (static.k8s.settings) virtualIP;
in
{
  services.kubernetes.controllerManager = {
    enable = true;
    extraOpts = lib.strings.concatStringsSep " " [
      "--feature-gates=KubeletInUserNamespace=true"
    ];
    kubeconfig = {
      caFile = "/etc/kubernetes/pki/ca.pem";
      certFile = "/etc/kubernetes/pki/controller-manager.pem";
      keyFile = "/etc/kubernetes/pki/controller-manager-key.pem";
      server = "https://${virtualIP}";
    };
    rootCaFile = "/etc/kubernetes/pki/ca.pem";
  };
}
