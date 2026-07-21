{
  lib,
  formats,
  cfssl,
  writeShellScriptBin,
  openssl,
}:
let
  inherit (lib) getExe getExe';
  inherit (import ./utils.nix { inherit formats; }) caConfig mkCsr;

  rootCACsr = mkCsr {
    CN = "k8s-root-ca";
    O = "Project Queentet RootCA";
  };
  etcdCA = mkCsr {
    CN = "etcd-ca";
    O = "Project Queentet Etcd CA";
  };
  k8sCA = mkCsr {
    CN = "kubernetes-ca";
    O = "Project Queentet Kubernetes CA";
  };
  k8sFrontProxyCA = mkCsr {
    CN = "kubernetes-front-proxy-ca";
    O = "Project Queentet Kubernetes Front Proxy CA";
  };
  vaultCA = mkCsr {
    CN = "vault-ca";
    O = "Project Queentet Vault CA";
  };
  genImCA = target: csr: ''
    OUT=$OUTDIR/${target}
    rm -rf "$OUT"
    mkdir -p "$OUT"
    pushd "$OUT"
    ${getExe cfssl} gencert -ca "$ROOTCA_DIR/ca.pem" -ca-key "$ROOTCA_DIR/ca-key.pem" \
      -config ${caConfig} \
      -profile intermediate_ca \
      ${csr} | ${getExe' cfssl "cfssljson"} -bare ca
    popd > /dev/null
  '';
in
writeShellScriptBin "genca" ''
  OUTDIR=''${1:-develop}

  ROOTDIR=''${FLAKE_ROOT:-$PWD}
  OUTDIR="$ROOTDIR/instances/secrets/$OUTDIR/pki"

  echo "Output directory: $OUTDIR"

  ROOTCA_DIR=$OUTDIR/RootCA
  rm -rf "$ROOTCA_DIR"
  mkdir -p "$ROOTCA_DIR"
  pushd "$ROOTCA_DIR"
  ${getExe cfssl} gencert -initca ${rootCACsr} | ${getExe' cfssl "cfssljson"} -bare ca
  popd > /dev/null

  ${genImCA "etcd" etcdCA}
  ${genImCA "kubernetes" k8sCA}
  ${genImCA "kubernetes-front-proxy" k8sFrontProxyCA}
  ${genImCA "vault" vaultCA}
  pushd "$OUTDIR/kubernetes"
  ${getExe openssl} genrsa -out sa.key 2048
  ${getExe openssl} rsa -in sa.key -pubout -out sa.pem
  popd > /dev/null
''
