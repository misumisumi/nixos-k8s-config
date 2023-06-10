{
  callPackage,
  cfssl,
  writeShellApplication,
}: let
  # 参考: https://qiita.com/iaoiui/items/fc2ea829498402d4a8e3
  # 各証明書の有効期限は10年
  inherit (callPackage ./utils/settings.nix {}) caConfig;
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


      out=./certs/generated

      ${callPackage ./etcd.nix {}}
      ${callPackage ./kubernetes.nix {}}
      ${callPackage ./coredns.nix {}}
      ${callPackage ./flannel.nix {}}
    '';
  }