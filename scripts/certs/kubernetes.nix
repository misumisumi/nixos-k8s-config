{ ws
, lib
, callPackage
, cfssl
, kubectl
,
}:
let
  inherit (callPackage ../../utils/resources.nix { }) resourcesByRoleAndWS;
  inherit (callPackage ../../utils/consts.nix { }) constByKey;
  inherit (callPackage ./utils/utils.nix { }) getAltNames mkCsr;

  virtualIPs = (constByKey "virtualIPs").k8s;

  caCsr = mkCsr "kubernetes-ca" {
    cn = "kubernetes-ca";
  };

  apiServerCsr = virtualIP:
    mkCsr "kube-api-server" {
      cn = "kubernetes";
      altNames =
        lib.singleton virtualIP
        ++ lib.singleton "10.32.0.1" # clusterIP of controlplane
        ++ getAltNames "controlplane" ws # Alternative names remain, as they might be useful for debugging purposes
        ++ getAltNames "loadbalancer" ws
        ++ [ "kubernetes" "kubernetes.default" "kubernetes.default.svc" "kubernetes.default.svc.cluster" "kubernetes.svc.cluster.local" ];
    };

  apiServerKubeletClientCsr = mkCsr "kube-api-server-kubelet-client" {
    cn = "kube-api-server";
    altNames = getAltNames "controlplane" ws;
    organization = "system:masters";
  };

  cmCsr = mkCsr "kube-controller-manager" {
    cn = "system:kube-controller-manager";
    organization = "system:kube-controller-manager";
  };

  adminCsr = mkCsr "admin" {
    cn = "admin";
    organization = "system:masters";
  };

  etcdClientCsr = mkCsr "etcd-client" {
    cn = "kubernetes";
    altNames = getAltNames "controlplane" ws;
  };

  # kubeletCsr = mkCsr "kubelet" {
  #   cn = "kubelet";
  # };

  proxyCsr = mkCsr "kube-proxy" {
    cn = "system:kube-proxy";
    organization = "system:node-proxier";
  };

  schedulerCsr = mkCsr "kube-scheduler" rec {
    cn = "system:kube-scheduler";
    organization = cn;
  };

  kubeletCsrs = role:
    map
      (r: {
        name = r.values.name;
        csr = mkCsr r.values.name {
          cn = "system:node:${r.values.name}";
          organization = "system:nodes";
          altNames = getAltNames role ws;
        };
      })
      (resourcesByRoleAndWS role "k8s" ws);

  kubeletScripts = role: map (csr: "genCert peer kubelet/${csr.name} ${csr.csr}") (kubeletCsrs role);
in
''
  mkdir -p $out/${ws}/kubernetes/{kubelet,apiserver}

  pushd $out/${ws}/etcd > /dev/null
  genCert client ../kubernetes/apiserver/etcd-client ${etcdClientCsr}
  popd > /dev/null

  pushd $out/${ws}/kubernetes > /dev/null

  genCa ${caCsr}
  genCert server apiserver/server ${apiServerCsr virtualIPs.${ws}}
  genCert server apiserver/kubelet-client ${apiServerKubeletClientCsr}
  genCert client controller-manager ${cmCsr}
  genCert client proxy ${proxyCsr}
  genCert client scheduler ${schedulerCsr}
  genCert client admin ${adminCsr}

  ${builtins.concatStringsSep "\n" (kubeletScripts "worker")}
  ${builtins.concatStringsSep "\n" (kubeletScripts "controlplane")}

  popd > /dev/null
''
