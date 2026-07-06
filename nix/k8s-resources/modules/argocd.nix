{
  charts,
  ...
}:
{
  applications.argocd = {
    namespace = "kube-system";

    helm.releases.traefik = {
      chart = charts.argocd.argocd;

      values = {
      };
    };
  };
}
