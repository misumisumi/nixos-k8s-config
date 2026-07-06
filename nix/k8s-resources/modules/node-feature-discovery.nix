{
  charts,
  ...
}:
{
  applications.node-feature-discovery = {
    namespace = "node-feature-discovery";
    createNamespace = true;

    helm.releases.node-feature-discovery = {
      # Use the traefik helm chart from nixhelm.
      chart = charts.node-feature-discovery.node-feature-discovery;
    };
  };
}
