{
  lib,
  static,
  ...
}:
let
  inherit (lib) concatStringsSep mapAttrsToList singleton;
  inherit (static.k8s.settings) apiserverAddress serviceClusterIpRange;
  etcdServers = mapAttrsToList (_: v: "https://${v.nodeIP}:2379") static.etcd;

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
      })
      [
        "endpoints"
        "services"
        "pods"
        "namespaces"
      ]
    ++ singleton {
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
  services.kubernetes = {
    inherit apiserverAddress;
    apiserver = {
      enable = true;
      allowPrivileged = true;
      inherit serviceClusterIpRange;

      extraOpts = concatStringsSep " " [
        "--feature-gates=KubeletInUserNamespace=true"
      ];

      # Using ABAC for CoreDNS running outside of k8s
      # is more simple in this case than using kube-addon-manager
      authorizationMode = [
        "RBAC"
        "Node"
        "ABAC"
      ];
      authorizationPolicy = corednsPolicies;

      etcd = {
        servers = etcdServers;
        caFile = "/etc/kubernetes/pki/etcd/ca.pem";
        certFile = "/etc/kubernetes/pki/apiserver-etcd-client.pem";
        keyFile = "/etc/kubernetes/pki/apiserver-etcd-client-key.pem";
      };

      clientCaFile = "/etc/kubernetes/pki/ca.pem";

      kubeletClientCaFile = "/etc/kubernetes/pki/ca.pem";
      kubeletClientCertFile = "/etc/kubernetes/pki/apiserver-kubelet-client.pem";
      kubeletClientKeyFile = "/etc/kubernetes/pki/apiserver-kubelet-client-key.pem";

      # TODO: separate from server keys
      serviceAccountKeyFile = "/etc/kubernetes/pki/sa.pem";
      serviceAccountSigningKeyFile = "/etc/kubernetes/pki/sa.key";

      tlsCertFile = "/etc/kubernetes/pki/apiserver.pem";
      tlsKeyFile = "/etc/kubernetes/pki/apiserver-key.pem";
    };
  };
}
