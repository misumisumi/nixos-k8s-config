{
  charts,
  ...
}:
{
  applications.cilium = {
    namespace = "kube-system";

    helm.releases.traefik = {
      chart = charts.cilium.cilium;

      values = {
        kubeProxyReplacement = "true";
        k8sServiceHost = "10.10.100.100";
        k8sServicePort = 443;
        # bgpControlPlane.enabled = true;
        ingressController = {
          enabled = true;
          loadbalancerMode = "shared";
        };
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
