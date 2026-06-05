{
  charts,
  ...
}:
{
  applications.cilium = {
    namespace = "kube-system";

    helm.releases.cilium = {
      chart = charts.cilium.cilium;

      values = {
        kubeProxyReplacement = true;
        k8sServiceHost = "10.10.100.100";
        k8sServicePort = 443;
        # bgpControlPlane.enabled = true;
        identityAllocationMode = "kvstore";
        etcd = {
          enabled = true;
          endpoints = [
            "https://10.10.100.20:2379"
            "https://10.10.100.21:2379"
            "https://10.10.100.22:2379"
          ];
          ssl = true;
        };
        hubble = {
          enabled = true;
          relay.enabled = true;
          ui.enabled = true;
        };
        ciliumEndpointSlice = {
          enabled = true;
          rateLimits = [
            {
              nodes = 0;
              limit = 10;
              burst = 20;
            }
            {

              nodes = 100;
              limit = 50;
              burst = 100;
            }
          ];
        };
      };
    };
  };
}
