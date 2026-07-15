{
  charts,
  lib,
  ...
}:
let
  inherit (lib) importYAML nixdyGenerators;
in
{
  nixidy.applicationImports = [
    (nixdyGenerators.fromChartCRDModule {
      name = "cert-manager";
      chart = charts.jetstack.cert-manager;
      extraOpts = [
        "--set"
        "crds.enabled=true"
      ];
    })
  ];
  applications.cert-manager = {
    namespace = "cert-manager";
    createNamespace = true;

    helm.releases.cert-manager = {
      chart = charts.jetstack.cert-manager;
    };

    resources = {
      clusterIssuers.letsencrypt-dns = importYAML ./clusterissuer.yaml;
      certificates.wildcard-misumi-sumi-com = importYAML ./wildcard-certificate.yaml;
    };
  };
}
