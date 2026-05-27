{
  lib,
  config,
  static,
  ...
}:
let
  inherit (static.k8s.settings) virtualIP;
in
{
  networking.firewall.allowedTCPPorts = [
    config.services.kubernetes.kubelet.port
  ];

  services.kubernetes.kubelet = rec {
    enable = true;
    extraOpts = lib.strings.concatStringsSep " " [
      "--fail-swap-on=false"
      "--feature-gates=KubeletInUserNamespace=true"
    ];
    unschedulable = true;
    kubeconfig = {
      caFile = "/etc/kubernetes/pki/ca.pem";
      certFile = tlsCertFile;
      keyFile = tlsKeyFile;
      server = "https://${virtualIP}";
    };
    clientCaFile = "/etc/kubernetes/pki/ca.pem";
    tlsCertFile = "/etc/kubernetes/pki/kubelet.pem";
    tlsKeyFile = "/etc/kubernetes/pki/kubelet-key.pem";
    taints."controlplane" = {
      key = "node-role.kubernetes.io/control-plane";
      value = "true";
      effect = "NoSchedule";
    };
  };
}
