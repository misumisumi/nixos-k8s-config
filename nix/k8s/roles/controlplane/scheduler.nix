{
  static,
  ...
}:
let
  inherit (static.k8s.settings) virtualIP;
in
{
  services.kubernetes.scheduler = {
    enable = true;
    kubeconfig = {
      caFile = "/etc/kubernetes/pki/ca.pem";
      certFile = "/etc/kubernetes/pki/scheduler.pem";
      keyFile = "/etc/kubernetes/pki/scheduler-key.pem";
      server = "https://${virtualIP}";
    };
  };
}
