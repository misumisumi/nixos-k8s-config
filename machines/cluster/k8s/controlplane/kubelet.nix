{
  lib,
  config,
  name,
  virtualIP,
  ...
}: let
  pwd = builtins.toPath (builtins.getEnv "PWD");
in {
  imports = [../node/default.nix];

  deployment.keys = {
    "ca.pem" = {
      keyFile = "${pwd}/certs/generated/kubernetes/ca.pem";
      destDir = "/var/lib/secrets/kubernetes";
      user = "kubernetes";
      permissions = "0644";
    };

    "kubelet.pem" = {
      keyFile = "${pwd}/certs/generated/kubernetes/kubelet" + "/${name}.pem";
      destDir = "/var/lib/secrets/kubernetes";
      user = "kubernetes";
    };

    "kubelet-key.pem" = {
      keyFile = "${pwd}/certs/generated/kubernetes/kubelet" + "/${name}-key.pem";
      destDir = "/var/lib/secrets/kubernetes";
      user = "kubernetes";
    };
  };

  networking.firewall.allowedTCPPorts = [
    config.services.kubernetes.kubelet.port
  ];

  services.kubernetes.clusterCidr = "10.200.0.0/16";

  services.kubernetes.kubelet = rec {
    enable = true;
    extraOpts = lib.strings.concatStringsSep " " [
      "--fail-swap-on=false"
      "--feature-gates=KubeletInUserNamespace=true"
    ];
    unschedulable = true;
    kubeconfig = {
      caFile = "/var/lib/secrets/kubernetes/ca.pem";
      certFile = tlsCertFile;
      keyFile = tlsKeyFile;
      server = "https://${virtualIP}";
    };
    clientCaFile = "/var/lib/secrets/kubernetes/ca.pem";
    tlsCertFile = "/var/lib/secrets/kubernetes/kubelet.pem";
    tlsKeyFile = "/var/lib/secrets/kubernetes/kubelet-key.pem";
    taints."controlplane" = {
      key = "node-role.kubernetes.io/control-plane";
      value = "true";
      effect = "NoSchedule";
    };
  };
}