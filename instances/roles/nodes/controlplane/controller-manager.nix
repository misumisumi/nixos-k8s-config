{
  lib,
  config,
  ...
}:
let
  inherit (config.services.kubernetes) apiserverAddress;
in
{
  services.kubernetes.controllerManager = {
    enable = true;
    kubeconfig = {
      caFile = "/etc/kubernetes/pki/ca.pem";
      certFile = "/etc/kubernetes/pki/controller-manager.pem";
      keyFile = "/etc/kubernetes/pki/controller-manager-key.pem";
      server = "https://${apiserverAddress}";
    };
    rootCaFile = "/etc/kubernetes/pki/ca.pem";
  };
}
