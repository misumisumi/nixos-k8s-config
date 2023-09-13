{ lib
, callPackage
, cfssl
, kubectl
, writeShellApplication
, ws ? "development"
}:
let
  # 参考: https://qiita.com/iaoiui/items/fc2ea829498402d4a8e3
  # 各証明書の有効期限は10年
  inherit (callPackage ../utils/consts.nix { }) constByKey;
  inherit (callPackage ./utils/settings.nix { }) caConfig;
  virtualIPs = (constByKey "virtualIPs").k8s;
  mkKubeConfig =
    { workspace
    , ip
    ,
    }: ''
      ${kubectl}/bin/kubectl --kubeconfig admin.kubeconfig config set-cluster ${workspace} \
        --certificate-authority=./kubernetes/ca.pem \
        --server=https://${ip}
      ${kubectl}/bin/kubectl --kubeconfig admin.kubeconfig config set-context ${workspace} \
        --user admin \
        --cluster ${workspace}
    '';
  multiKubeConfig = lib.mapAttrsToList (workspace: ip: mkKubeConfig { inherit workspace ip; }) virtualIPs;
in
writeShellApplication {
  name = "mkcerts";
  text = ''
    set -e

    # Generates a CA, if one does not exist, in the current directory.
    function genCa() {
      csrjson=$1
      [ -n "$csrjson" ] || { echo "Usage: genCa CSRJSON" && return 1; }
      [ -f ca.pem ] && { echo "$(realpath ca.pem) exists, not replacing the CA" && return 0; }
      ${cfssl}/bin/cfssl gencert -loglevel 2 -initca "$csrjson" | ${cfssl}/bin/cfssljson -bare ca
    }

    # Generates a certificate signed by ca.pem from the current directory
    # (convention over configuration).
    function genCert() {
      profile=$1
      output=$2 # e.g. `apiserver/client` will result in `apiserver/client.pem` and `apiserver/client-key.pem`
      csrjson=$3

      { [ -n "$profile" ] && [ -n "$output" ] && [ -n "$csrjson" ]; } \
          || { echo "Usage: genCert PROFILE OUTPUT CSRJSON" && return 1; }

      ${cfssl}/bin/cfssl gencert \
          -loglevel 2 \
          -ca ca.pem \
          -ca-key ca-key.pem \
          -config ${caConfig} \
          -profile "$profile" \
          "$csrjson" \
          | ${cfssl}/bin/cfssljson -bare "$output"
    }


    out=./.kube/
    ${callPackage ./etcd.nix {inherit ws;}}
    ${callPackage ./kubernetes.nix {inherit ws;}}
    ${callPackage ./coredns.nix {inherit ws;}}
    ${callPackage ./flannel.nix {inherit ws;}}
    pushd $out > /dev/null

    ${kubectl}/bin/kubectl --kubeconfig admin.kubeconfig config set-credentials admin \
        --client-certificate=./kubernetes/admin.pem \
        --client-key=./kubernetes/admin-key.pem
    ${builtins.concatStringsSep "\n" multiKubeConfig}
    ${kubectl}/bin/kubectl --kubeconfig admin.kubeconfig config use-context development > /dev/null

    popd > /dev/null
  '';
}
