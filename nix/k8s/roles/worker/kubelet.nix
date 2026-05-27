{
  lib,
  config,
  resourcesByRoles,
  virtualIP,
  ...
}:
let
  nodes = map (
    r: "${r.values.ipv4_address} ${builtins.head (builtins.match "^.*([0-9])" r.values.name)}"
  ) (resourcesByRoles [ "etcd" "controlplane" "loadbalancer" "worker" ] "k8s");
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
    kubernetes.clusterCidr = "10.200.0.0/16";

    kubernetes.kubelet = rec {
      enable = true;
      extraOpts = lib.strings.concatStringsSep " " [
        "--root-dir=/var/lib/kubelet"
        "--fail-swap-on=false"
        "--feature-gates=KubeletInUserNamespace=true"
      ];
      unschedulable = false;
      kubeconfig = {
        caFile = "/etc/kubernetes/pki/ca.pem";
        certFile = tlsCertFile;
        keyFile = tlsKeyFile;
        server = "https://${virtualIP}";
      };
      clientCaFile = "/etc/kubernetes/pki/ca.pem";
      tlsCertFile = "/etc/kubernetes/pki/kubelet.pem";
      tlsKeyFile = "/etc/kubernetes/pki/kubelet-key.pem";
    };
  };
}
