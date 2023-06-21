{
  lib,
  pkgs,
  cfssl,
  kubectl,
}: let
  inherit (pkgs.callPackage ../utils/resources.nix {}) resourcesByRole;
  inherit (pkgs.callPackage ../utils/consts.nix {}) virtualIP;
  inherit (import ../utils/utils.nix) nodeIP;
  inherit (pkgs.callPackage ./utils/utils.nix {}) getAltNames mkCsr;

  caCsr = mkCsr "kubernetes-ca" {
    cn = "kubernetes-ca";
  };

  apiServerCsr = mkCsr "kube-api-server" {
    cn = "kubernetes";
    altNames =
      lib.singleton virtualIP
      ++ lib.singleton "10.32.0.1" # clusterIP of controlplane
      ++ getAltNames "controlplane" # Alternative names remain, as they might be useful for debugging purposes
      ++ getAltNames "loadbalancer"
      ++ ["kubernetes" "kubernetes.default" "kubernetes.default.svc" "kubernetes.default.svc.cluster" "kubernetes.svc.cluster.local"];
  };

  apiServerKubeletClientCsr = mkCsr "kube-api-server-kubelet-client" {
    cn = "kube-api-server";
    altNames = getAltNames "controlplane";
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
    altNames = getAltNames "controlplane";
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
        # TODO: unify with getAltNames?
        altNames = [r.values.name (nodeIP r)];
      };
    })
    (resourcesByRole role);

  kubeletScripts = role: map (csr: "genCert peer kubelet/${csr.name} ${csr.csr}") (kubeletCsrs role);
in ''
  mkdir -p $out/kubernetes/{apiserver,kubelet}

  pushd $out/etcd > /dev/null
  genCert client ../kubernetes/apiserver/etcd-client ${etcdClientCsr}
  popd > /dev/null

  pushd $out/kubernetes > /dev/null

  genCa ${caCsr}
  genCert server apiserver/server ${apiServerCsr}
  genCert server apiserver/kubelet-client ${apiServerKubeletClientCsr}
  genCert client controller-manager ${cmCsr}
  genCert client proxy ${proxyCsr}
  genCert client scheduler ${schedulerCsr}
  genCert client admin ${adminCsr}

  ${builtins.concatStringsSep "\n" (kubeletScripts "worker")}
  ${builtins.concatStringsSep "\n" (kubeletScripts "controlplane")}

  popd > /dev/null
  pushd $out > /dev/null

  ${kubectl}/bin/kubectl --kubeconfig admin.kubeconfig config set-credentials admin \
      --client-certificate=./kubernetes/admin.pem \
      --client-key=./kubernetes/admin-key.pem
  ${kubectl}/bin/kubectl --kubeconfig admin.kubeconfig config set-cluster lxd \
      --certificate-authority=./kubernetes/ca.pem \
      --server=https://${virtualIP}
  ${kubectl}/bin/kubectl --kubeconfig admin.kubeconfig config set-context lxd \
      --user admin \
      --cluster lxd
  ${kubectl}/bin/kubectl --kubeconfig admin.kubeconfig config use-context lxd > /dev/null

  popd > /dev/null
''