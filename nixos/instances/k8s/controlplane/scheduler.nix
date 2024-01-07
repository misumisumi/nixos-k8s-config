{ virtualIP
, ...
}:
{
  services.kubernetes.scheduler = {
    enable = true;
    kubeconfig = {
      caFile = "/var/lib/secrets/kubernetes/ca.pem";
      certFile = "/var/lib/secrets/kubernetes/scheduler.pem";
      keyFile = "/var/lib/secrets/kubernetes/scheduler-key.pem";
      server = "https://${virtualIP}";
    };
  };
}
