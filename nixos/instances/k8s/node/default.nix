{ lib
, virtualIP
, workspace
, ...
}:
let
  pwd = builtins.toPath (builtins.getEnv "PWD");
in
{
  imports = [ ./containerd.nix ./coredns.nix ./flannel.nix ];

  deployment.keys = {
    "proxy.pem" = {
      keyFile = "${pwd}/.kube/${workspace}/kubernetes/proxy.pem";
      destDir = "/var/lib/secrets/kubernetes";
      user = "kubernetes";
    };

    "proxy-key.pem" = {
      keyFile = "${pwd}/.kube/${workspace}/kubernetes/proxy-key.pem";
      destDir = "/var/lib/secrets/kubernetes";
      user = "kubernetes";
    };
  };

  services.kubernetes.proxy = {
    enable = true;
    extraOpts = lib.strings.concatStringsSep " " [
      "--conntrack-max-per-core=0"
      "--conntrack-tcp-timeout-established=0"
      "--conntrack-tcp-timeout-close-wait=0"
    ];
    kubeconfig = {
      caFile = "/var/lib/secrets/kubernetes/ca.pem";
      certFile = "/var/lib/secrets/kubernetes/proxy.pem";
      keyFile = "/var/lib/secrets/kubernetes/proxy-key.pem";
      server = "https://${virtualIP}";
    };
  };
}