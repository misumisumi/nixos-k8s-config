{
  config,
  charts,
  lib,
  generators,
  ...
}:
let
  inherit (builtins) readFile toJSON;
  inherit (lib) importTOML importYAML extraPkgs;
  inherit (config.nixidy.target) branch;

  # static =
  #   if branch == "devlop" then
  #     importTOML ../../k8s/roles/static_dev.toml
  #   else
  #     importTOML ../../k8s/roles/static.toml;
  static = importTOML ../../../k8s/roles/static_dev.toml;
  crdFiles = [
    "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumbgpadvertisements.yaml"
    "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumbgpclusterconfigs.yaml"
    "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumbgpnodeconfigoverrides.yaml"
    "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumbgpnodeconfigs.yaml"
    "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumbgppeerconfigs.yaml"
    "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumclusterwidenetworkpolicies.yaml"
    "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumegressgatewaypolicies.yaml"
    "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumnetworkpolicies.yaml"
  ];
in
{
  nixidy.applicationImports = [
    (generators.fromCRDModule {
      name = "cilium";
      inherit (extraPkgs.cilium) src;
      inherit crdFiles;
    })
  ];
  applications.cilium = {
    namespace = "kube-system";
    resources = {
      secrets.cilium-etcd-secrets = {
        stringData = {
          "etcd-client-ca.crt" = "${readFile ../../secrets/${branch}/cilium/ca.pem}";
          "etcd-client.key" = "${readFile ../../secrets/${branch}/cilium/client-key.pem}";
          "etcd-client.crt" = "${readFile ../../secrets/${branch}/cilium/client.pem}";
        };
      };
      ciliumBGPAdvertisements.advertisement = importYAML ./bgp/advertisement.yaml;
      ciliumBGPClusterConfigs.cluster = importYAML ./bgp/cluster.yaml;
      ciliumBGPPeerConfigs.peer = importYAML ./bgp/peer.yaml;
      ciliumClusterwideNetworkPolicies.cluster = importYAML ./network-policies/cluster.yaml;
    };
    yamls = map toJSON (
      generators.crdObjects {
        inherit (extraPkgs.cilium) src;
        inherit crdFiles;
      }
    );

    helm.releases.cilium = {
      chart = charts.cilium.cilium;

      includeCRDs = true;
      values = {
        kubeProxyReplacement = true;
        k8sServiceHost = static.k8s.settings.apiserverAddress;
        k8sServicePort = 443;
        # bgpControlPlane.enabled = true;
        identityAllocationMode = "kvstore";
        etcd = {
          enabled = true;
          endpoints = map (ip: "https://${ip}:2379") static.nodes.etcd.nodeIPs;
          ssl = true;
        };
        hubble = {
          enabled = true;
          relay.enabled = true;
          ui.enabled = true;
        };
        ciliumEndpointSlice = {
          enabled = true;
          rateLimits = [
            {
              nodes = 0;
              limit = 10;
              burst = 20;
            }
            {

              nodes = 100;
              limit = 50;
              burst = 100;
            }
          ];
        };
        hostFirewall.enabled = true;
        bgpControlPlane.enabled = true;
      };
    };
  };
}
