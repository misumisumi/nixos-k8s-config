{
  lib,
  config,
  ...
}:
{
  networking = {
    firewall.allowedTCPPorts = [
      config.services.kubernetes.kubelet.port
    ];
  };

  services = {
    kubernetes = {
      kubelet = rec {
        enable = true;
        extraOpts = lib.strings.concatStringsSep " " [
          "--root-dir=/var/lib/kubelet"
          "--fail-swap-on=false"
          "--node-labels=role.storage=ceph"
        ];
        unschedulable = false;
        kubeconfig = {
          caFile = clientCaFile;
          certFile = tlsCertFile;
          keyFile = tlsKeyFile;
          server = "https://${config.services.kubernetes.apiserverAddress}";
        };
        clientCaFile = "/etc/kubernetes/pki/ca.pem";
        tlsCertFile = "/etc/kubernetes/pki/kubelet.pem";
        tlsKeyFile = "/etc/kubernetes/pki/kubelet-key.pem";
      };
    };
  };
}
