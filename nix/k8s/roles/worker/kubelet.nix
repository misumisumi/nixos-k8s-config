{
  lib,
  config,
  ...
}:
{
  networking = {
    firewall.allowedTCPPorts = [
      config.services.kubernetes.kubelet.port
      7946 # metallb
      6789 # rook/ceph
      3300 # rook/ceph
      8443 # rook/ceph
    ];
    firewall.allowedTCPPortRanges = [
      {
        from = 6800;
        to = 7300;
      }
    ];
  };

  services = {
    kubernetes = {
      kubelet = rec {
        enable = true;
        extraOpts = lib.strings.concatStringsSep " " [
          "--root-dir=/var/lib/kubelet"
          "--fail-swap-on=false"
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
