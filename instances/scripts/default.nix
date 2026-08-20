{
  lib,
  kubectl,
  kubernetes-helm,
  vault,
  writeShellScriptBin,
}:
let
  inherit (lib) mapAttrs' nameValuePair;
  variants = {
    production = "prod";
    develop = "dev";
    test = "test";
  };
  static = {
    production = import ../roles/static.nix;
    develop = import ../roles/static_dev.nix;
    test = import ../roles/static_dev.nix;
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
