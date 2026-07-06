{ lib, generators, ... }:
let
  inherit (builtins) toJSON;
  inherit (lib) extraPkgs;
  crdFiles = [
    "config/crd/standard/gateway.networking.k8s.io_gatewayclasses.yaml"
    "config/crd/standard/gateway.networking.k8s.io_gateways.yaml"
    "config/crd/standard/gateway.networking.k8s.io_grpcroutes.yaml"
    "config/crd/standard/gateway.networking.k8s.io_httproutes.yaml"
    "config/crd/standard/gateway.networking.k8s.io_referencegrants.yaml"
    "config/crd/standard/gateway.networking.k8s.io_backendtlspolicies.yaml"
    "config/crd/standard/gateway.networking.k8s.io_listenersets.yaml"
    "config/crd/standard/gateway.networking.k8s.io_tcproutes.yaml"
    "config/crd/standard/gateway.networking.k8s.io_tlsroutes.yaml"
    "config/crd/standard/gateway.networking.k8s.io_udproutes.yaml"
    "config/crd/standard/gateway.networking.k8s.io_vap_safeupgrades.yaml"
  ];
in
{
  nixidy.applicationImports = [
    (generators.fromCRDModule {
      name = "cilium";
      inherit (extraPkgs.gateway-api) src;
      inherit crdFiles;
    })
  ];
  applications.gateway-api = {
    yamls = map toJSON (
      generators.crdObjects {
        inherit (extraPkgs.gateway-api) src;
        inherit crdFiles;
      }
    );
  };
}
