{
  lib,
  coreutils,
  formats,
  cfssl,
  writeShellScriptBin,
}:
let
  inherit (lib)
    concatStringsSep
    flatten
    getExe
    getExe'
    imap1
    importTOML
    mapAttrs'
    nameValuePair
    mapAttrsToList
    splitString
    take
    ;
  inherit (import ./utils.nix { inherit formats; }) caConfig mkCsr;

  #NOTE: https://kubernetes.io/docs/setup/best-practices/certificates/#all-certificates
  etcd =
    static:
    let
      nodes =
        roles:
        flatten (
          map (
            role:
            imap1 (i: ip: [
              "${role}${toString i}"
              "${ip}"
            ]) static.nodes.${role}.nodeIPs
          ) roles
        );
    in
    {
      server = {
        profile = "both";
        csr = mkCsr {
          O = "kube-etcd";
          CN = "kube-etcd";
          hosts = [
            "localhost"
            "127.0.0.1"
          ]
          ++ (nodes [ "etcd" ]);
        };
      };
      healthcheck-client = {
        profile = "client";
        csr = mkCsr {
          O = "kube-etcd-healthcheck-client";
          CN = "kube-etcd-healthcheck-client";
        };
      };
      apiserver-etcd-client = {
        profile = "client";
        csr = mkCsr {
          O = "kube-apiserver-etcd-client";
          CN = "kube-apiserver-etcd-client";
        };
      };
      peer = {
        profile = "peer";
        csr = mkCsr {
          O = "kube-etcd-peer";
          CN = "kube-etcd-peer";
          hosts = [
            "localhost"
            "127.0.0.1"
          ]
          ++ nodes [
            "etcd"
            # "controlplane"
            # "worker"
          ];
        };
      };
    };
  k8s = static: {
    coredns = {
      profile = "client";
      csr = mkCsr {
        CN = "system:coredns";
        O = "system:coredns";
      };
    };
    apiserver = {
      profile = "server";
      csr = mkCsr {
        CN = "kube-apiserver";
        O = "kube-apiserver";
        hosts =
          flatten (
            imap1 (i: v: [
              "controlplane${toString i}"
              (splitString "," v)
            ]) static.nodes.controlplane.nodeIPs
          )
          ++ [
            "${static.k8s.settings.apiserverAddress}"
            "${concatStringsSep "." (
              (take 3 (splitString "." static.k8s.settings.serviceClusterIpRange)) ++ [ "1" ]
            )}"
            "kubernetes"
            "kubernetes.default"
            "kubernetes.default.svc"
            "kubernetes.default.svc.cluster"
            "kubernetes.svc.cluster.local"
          ];
      };
    };
    apiserver-kubelet-client = {
      profile = "client";
      csr = mkCsr {
        CN = "k8s-apiserver-kubelet-client";
        O = "system:masters";
        hosts = flatten (
          imap1 (i: v: [
            "controlplane${toString i}"
            (splitString "," v)
          ]) static.nodes.controlplane.nodeIPs
        );
      };
    };
    controller-manager = {
      profile = "client";
      csr = mkCsr {
        CN = "system:kube-controller-manager";
        O = "system:kube-controller-manager";
      };
    };
    admin = {
      profile = "client";
      csr = mkCsr {
        CN = "admin";
        O = "system:masters";
      };
    };
    scheduler = {
      profile = "client";
      csr = mkCsr {
        CN = "system:kube-scheduler";
        O = "system:kube-scheduler";
      };
    };
  };
  kubeletCsr = hostname: nodeIP: {
    profile = "both";
    csr = mkCsr {
      CN = "system:node:${hostname}";
      O = "system:nodes";
      hosts = [
        hostname
        nodeIP
      ];
    };
  };
  script =
    variant: abbr: static:
    let
      genCerts =
        target: parentCA:
        "${concatStringsSep "\n" (
          mapAttrsToList (k: v: "genCert ${k} ${v.profile} ${v.csr} ${parentCA}") target
        )}";
    in
    writeShellScriptBin "gencerts.${abbr}" ''
      ROOTDIR=''${FLAKE_ROOT:-$PWD}
      OUTDIR="$ROOTDIR/nix/k8s/secrets/${variant}/pki"

      echo "Output directory: $OUTDIR"

      function genCert() {
        output=$1 # e.g. `apiserver/client` will result in `apiserver/client.pem` and `apiserver/client-key.pem`
        profile=$2
        csrjson=$3
        caDir=$4
        caDir="$OUTDIR/$caDir"

        [ ! -d "$caDir" ] && echo "Intermediate CA not found in $caDir, please generate Parent CA first using genca script" && exit 1

        { [ -n "$profile" ] && [ -n "$output" ] && [ -n "$csrjson" ] && [ -n "$caDir" ]; } \
            || { echo "Usage: genCert PROFILE OUTPUT CSRJSON PARENT_CA_DIR" && return 1; }

        ${getExe cfssl} gencert \
            -loglevel 2 \
            -ca "$caDir/ca.pem" \
            -ca-key "$caDir/ca-key.pem" \
            -config ${caConfig} \
            -profile "$profile" \
            "$csrjson" \
            | ${getExe' cfssl "cfssljson"} -bare "$output"
        ${getExe' coreutils "cat"} "$output.pem" "$caDir/ca.pem" > $output-chain.pem
      }

      ETCD_DIR="$OUTDIR/etcd"
      mkdir -p "$ETCD_DIR"
      pushd $ETCD_DIR > /dev/null
      ${genCerts (etcd static) "etcd"}
      popd > /dev/null

      K8S_DIR="$OUTDIR/kubernetes"
      mkdir -p "$K8S_DIR"
      pushd $K8S_DIR > /dev/null
      ${genCerts (k8s static) "kubernetes"}
      popd > /dev/null

      NODES_DIR="$OUTDIR/kubernetes/controlplanes"
      mkdir -p "$NODES_DIR"
      pushd $NODES_DIR > /dev/null
      ${concatStringsSep "\n" (
        imap1 (
          i: nodeIP:
          let
            conf = kubeletCsr "controlplane${toString i}" nodeIP;
          in
          "genCert controlplane${toString i} ${conf.profile} ${conf.csr} kubernetes"
        ) static.nodes.controlplane.nodeIPs
      )}
      popd > /dev/null
      NODES_DIR="$OUTDIR/kubernetes/workers"
      mkdir -p "$NODES_DIR"
      pushd $NODES_DIR > /dev/null
      ${concatStringsSep "\n" (
        imap1 (
          i: nodeIP:
          let
            conf = kubeletCsr "worker${toString i}" nodeIP;
          in
          "genCert worker${toString i} ${conf.profile} ${conf.csr} kubernetes"
        ) static.nodes.worker.nodeIPs
      )}
      popd > /dev/null
    '';
  variants = {
    production = {
      abbr = "prod";
      static = importTOML ../roles/static.toml;
    };
    develop = {
      abbr = "dev";
      static = importTOML ../roles/static_dev.toml;
    };
    test = {
      abbr = "test";
      static = importTOML ../roles/static_dev.toml;
    };
  };
in
mapAttrs' (k: v: nameValuePair "gencerts-${v.abbr}" (script k v.abbr v.static)) variants
