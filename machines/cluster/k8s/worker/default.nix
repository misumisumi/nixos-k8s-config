{
  lib,
  config,
  name,
  resourcesByRoles,
  virtualIP,
  ...
}: let
  pwd = builtins.toPath (builtins.getEnv "PWD");
  nodes = map (r: "${r.values.ip_address} ${r.values.id}") (resourcesByRoles ["etcd" "controlplane" "loadbalancer" "worker"]);
in {
  imports = [../node/default.nix];

  deployment.keys = {
    "ca.pem" = {
      keyFile = "${pwd}/.kube/kubernetes/ca.pem";
      destDir = "/var/lib/secrets/kubernetes";
      user = "kubernetes";
      permissions = "0644";
    };

    "kubelet.pem" = {
      keyFile = "${pwd}/.kube/kubernetes/kubelet" + "/${name}.pem";
      destDir = "/var/lib/secrets/kubernetes";
      user = "kubernetes";
    };

    "kubelet-key.pem" = {
      keyFile = "${pwd}/.kube/kubernetes/kubelet" + "/${name}-key.pem";
      destDir = "/var/lib/secrets/kubernetes";
      user = "kubernetes";
    };
  };
  boot.kernelModules = ["ceph"];

  networking.extraHosts = lib.strings.concatMapStrings (x: x + "\n") nodes;
  networking.firewall.allowedTCPPorts = [
    config.services.kubernetes.kubelet.port
    7946 # metallb
    6789 # rook/ceph
    3300 # rook/ceph
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