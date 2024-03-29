{ lib
, resourcesByRole
, ...
}:
let
  etcdServers = map (r: "https://${r.values.name}:2379") (resourcesByRole "etcd" "k8s");

  corednsPolicies =
    map
      (r: {
        apiVersion = "abac.authorization.kubernetes.io/v1beta1";
        kind = "Policy";
        spec = {
          user = "system:coredns";
          namespace = "*";
          resource = r;
          readonly = true;
        };
      }) [ "endpoints" "services" "pods" "namespaces" ]
    ++ lib.singleton
      {
        apiVersion = "abac.authorization.kubernetes.io/v1beta1";
        kind = "Policy";
        spec = {
          user = "system:coredns";
          namespace = "*";
          resource = "endpointslices";
          apiGroup = "discovery.k8s.io";
          readonly = true;
        };
      };
in
{
  networking.firewall.allowedTCPPorts = [ 6443 ];

  services.kubernetes.apiserver = {
    enable = true;
    allowPrivileged = true;
    serviceClusterIpRange = "10.32.0.0/24";
    extraOpts = lib.strings.concatStringsSep " " [
      "--feature-gates=KubeletInUserNamespace=true"
    ];

    # Using ABAC for CoreDNS running outside of k8s
    # is more simple in this case than using kube-addon-manager
    authorizationMode = [ "RBAC" "Node" "ABAC" ];
    authorizationPolicy = corednsPolicies;

    etcd = {
      servers = etcdServers;
      caFile = "/var/lib/secrets/kubernetes/apiserver/api-etcd-ca.pem";
      certFile = "/var/lib/secrets/kubernetes/apiserver/api-etcd-client.pem";
      keyFile = "/var/lib/secrets/kubernetes/apiserver/api-etcd-client-key.pem";
    };

    clientCaFile = "/var/lib/secrets/kubernetes/ca.pem";

    kubeletClientCaFile = "/var/lib/secrets/kubernetes/ca.pem";
    kubeletClientCertFile = "/var/lib/secrets/kubernetes/apiserver/kubelet-client.pem";
    kubeletClientKeyFile = "/var/lib/secrets/kubernetes/apiserver/kubelet-client-key.pem";

    # TODO: separate from server keys
    serviceAccountKeyFile = "/var/lib/secrets/kubernetes/apiserver/server.pem";
    serviceAccountSigningKeyFile = "/var/lib/secrets/kubernetes/apiserver/server-key.pem";

    tlsCertFile = "/var/lib/secrets/kubernetes/apiserver/server.pem";
    tlsKeyFile = "/var/lib/secrets/kubernetes/apiserver/server-key.pem";
  };
}
