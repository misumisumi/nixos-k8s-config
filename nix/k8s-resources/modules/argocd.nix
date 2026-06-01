{
  charts,
  ...
}:
{
  applications.cilium = {
    namespace = "kube-system";

    helm.releases.traefik = {
      chart = charts.argocd.argocd;

      values = {
      };
    };
  };
}
