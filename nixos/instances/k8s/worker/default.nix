{ lib
, config
, name
, resourcesByRoles
, virtualIP
, ...
}:
let
  nodes = map
    (r: "${r.values.ip_address} ${builtins.head (builtins.match "^.*([0-9])" r.values.name)}")
    (resourcesByRoles [ "etcd" "controlplane" "loadbalancer" "worker" ] "k8s");
in
{
  imports = [
    ../../init
    ../autoresources.nix
    ../node
    ./hive.nix
  ];

  boot.kernelModules = [ "ceph" ];

  networking.extraHosts = lib.strings.concatMapStrings (x: x + "\n") nodes;
  networking.firewall.allowedTCPPorts = [
    config.services.kubernetes.kubelet.port
    7946 # metallb
    6789 # rook/ceph
    3300 # rook/ceph
    8443 # rook/ceph
  ];
  networking.firewall.allowedTCPPortRanges = [
    {
      from = 6800;
      to = 7300;
    }
  ];

  services.kubernetes.clusterCidr = "10.200.0.0/16";

  services.kubernetes.kubelet = rec {
    enable = true;
    extraOpts = lib.strings.concatStringsSep " " [
      "--root-dir=/var/lib/kubelet"
      "--fail-swap-on=false"
      "--feature-gates=KubeletInUserNamespace=true"
    ];
    unschedulable = false;
    kubeconfig = {
      caFile = "/var/lib/secrets/kubernetes/ca.pem";
      certFile = tlsCertFile;
      keyFile = tlsKeyFile;
      server = "https://${virtualIP}";
    };
    clientCaFile = "/var/lib/secrets/kubernetes/ca.pem";
    tlsCertFile = "/var/lib/secrets/kubernetes/kubelet.pem";
    tlsKeyFile = "/var/lib/secrets/kubernetes/kubelet-key.pem";
  };
}
