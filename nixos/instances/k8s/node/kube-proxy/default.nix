{ lib
, virtualIP
, ...
}:
{
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
