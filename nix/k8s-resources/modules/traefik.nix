{
  charts,
  ...
}:
{
  applications.traefik = {
    namespace = "traefik";
    createNamespace = true;

    helm.releases.traefik = {
      # Use the traefik helm chart from nixhelm.
      chart = charts.traefik.traefik;

      # Example values to pass to the Helm Chart.
      values = {
        ingressClass.enabled = false;
        ingressRoute.dashboard.enabled = false;
        experimental.kubernetesGateway.enabled = true;
        gateway = {
          enabled = true;
        };
        gatewayClass.enabled = true;
        providers = {
          kubernetesIngress.enabled = false;
          kubernetesGateway.enabled = true;
        };
        ports.traefik.expose.default = true;
      };
    };
  };
}
