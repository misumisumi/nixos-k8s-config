{
  lib,
  kubectl,
  kubernetes-helm,
  vault,
  writeShellScriptBin,
}:
let
  inherit (lib) mapAttrs' nameValuePair importTOML;
  variants = {
    production = "prod";
    develop = "dev";
    test = "test";
  };
  static = {
    production = importTOML ../roles/static.toml;
    develop = importTOML ../roles/static_dev.toml;
    test = importTOML ../roles/static_dev.toml;
  };
in
(mapAttrs' (
  k: v:
  nameValuePair "k-${v}" (
    writeShellScriptBin "k-${v}" ''
      ${kubectl}/bin/kubectl --kubeconfig ${../secrets/${k}/kubeconfig} $@
    ''
  )
) variants)
// (mapAttrs' (
  k: v:
  nameValuePair "helm-${v}" (
    writeShellScriptBin "helm-${v}" ''
      ${kubernetes-helm}/bin/helm --kubeconfig ${../secrets/${k}/kubeconfig} $@
    ''
  )
) variants)
// (mapAttrs' (
  k: v:
  nameValuePair "v-${v}" (
    writeShellScriptBin "v-${v}" ''
      export VAULT_ADDR=https://${static.${k}.vault.vault.vip}:8200
      export VAULT_CACERT="$FLAKE_ROOT/instances/secrets/${k}/pki/RootCA/ca.pem"
      ${vault}/bin/vault $@
    ''
  )
) variants)
