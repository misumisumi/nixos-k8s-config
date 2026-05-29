{
  lib,
  kubectl,
  kubernetes-helm,
  writeShellScriptBin,
}:
let
  inherit (lib) mapAttrs' nameValuePair;
  variants = {
    production = "prod";
    develop = "dev";
    test = "test";
  };
in
(mapAttrs' (
  k: v:
  nameValuePair "k-${v}" (
    writeShellScriptBin "k.${v}" ''
      ${kubectl}/bin/kubectl --kubeconfig ${../secrets/${k}/kubeconfig} $@
    ''
  )
) variants)
// (mapAttrs' (
  k: v:
  nameValuePair "helm-${v}" (
    writeShellScriptBin "helm.${v}" ''
      ${kubernetes-helm}/bin/helm --kubeconfig ${../secrets/${k}/kubeconfig} $@
    ''
  )
) variants)
