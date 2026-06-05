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
        ingressClass.enabled = true;
        ingressRoute.dashboard.enabled = true;
        ports.traefik.expose.default = true;
      };
    };
  };
}
