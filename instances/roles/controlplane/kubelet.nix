{
  lib,
  config,
  ...
}:
{
  networking.firewall.allowedTCPPorts = [
    config.services.kubernetes.kubelet.port
  ];

  services.kubernetes.kubelet = rec {
    enable = true;
    extraOpts = lib.strings.concatStringsSep "\\n" [
      "--fail-swap-on=false"
    ];
    unschedulable = true;
    kubeconfig = {
      caFile = clientCaFile;
      certFile = tlsCertFile;
      keyFile = tlsKeyFile;
      server = "https://${config.services.kubernetes.apiserverAddress}";
    };
    clientCaFile = "/etc/kubernetes/pki/ca.pem";
    tlsCertFile = "/etc/kubernetes/pki/kubelet.pem";
    tlsKeyFile = "/etc/kubernetes/pki/kubelet-key.pem";
    taints."control-plane" = {
      key = "node-role.kubernetes.io/control-plane";
      value = "true";
      effect = "NoSchedule";
    };
  };
}
