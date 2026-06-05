{
  charts,
  ...
}:
{
  applications.coredns = {
    namespace = "kube-system";
    helm.releases.coredns = {
      chart = charts.coredns.coredns;
      values = {
        replicaCount = 2;
        priorityClassName = "system-cluster-critical";
        isClusterService = true;
        service = {
          clusterIP = "10.100.0.254";
          name = "kube-dns";
        };
        serviceAccount = {
          create = true;
          name = "coredns";
        };
        rbac.create = true;
      };
    };

  };
}
