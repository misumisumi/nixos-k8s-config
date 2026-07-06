{ charts, ... }:
{
  applications.external-dns = {
    namespace = "external-dns";
    createNamespace = true;

    helm.releases.external-dns = {
      chart = charts.external-dns.external-dns;
      values = {
        serviceAccount = {
          create = true;
          name = "external-dns";
        };
        rbac = {
          create = true;
          additionalRules = {
            apiGroups = [ "gateway.networking.k8s.io" ];
            resources = [
              "gateways"
              # "tlsroutes"
              "httproutes"
            ];
            verbs = [
              "get"
              "watch"
              "list"
            ];
          };
        };
        provider.name = "pdns";
        sources = [
          # not use ingress
          "service"
          "gateway-httproute"
          # "gateway-tlsroute" # This is experimental in gateway-api
        ];
        registry = "txt";
        txtOwnerId = "home-k8s-cluster";
        policy = "sync";
        extraArgs = [
          "--pdns-server=http:172.16.1.2:8081"
          "--pdns-api-key=hogehoge"
        ];
      };
    };

  };
}
