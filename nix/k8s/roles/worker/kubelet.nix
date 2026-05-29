{
  lib,
  config,
  static,
  ...
}:
let
  inherit (lib)
    flatten
    imap1
    mapAttrsToList
    ;

  nodes =
    flatten (
      map (role: imap1 (i: ip: "${role}${toString i} ${ip}") static.k8s.${role}.nodeIPs) [
        "controlplane"
        "worker"
      ]
    )
    ++ (mapAttrsToList (k: v: "${k} ${v.nodeIP}") static.etcd);
in
{
  networking = {
    extraHosts = lib.strings.concatMapStrings (x: x + "\n") nodes;
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
      inherit (static.k8s.settings) apiserverAddress clusterCidr;

      kubelet = rec {
        enable = true;
        extraOpts = lib.strings.concatStringsSep " " [
          "--root-dir=/var/lib/kubelet"
          "--fail-swap-on=false"
          "--feature-gates=KubeletInUserNamespace=true"
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
