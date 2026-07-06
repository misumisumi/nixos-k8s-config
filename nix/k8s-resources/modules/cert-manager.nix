{ charts, ... }:
{
  applications.cert-manager = {
    namespace = "cert-manager";
    createNamespace = true;

    helm.releases.cert-manager = {
      chart = charts.cert-manager.cert-manager;
      values = {
        crds.enabled = true;
      };
    };

  };
}
