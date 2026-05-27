{
  callPackage,
  kubectl,
  kubernetes-helm,
  writeShellScriptBin,
}:
{
  check-k8s = callPackage ./check-k8s.nix { };
  k = writeShellScriptBin "k" ''
    ${kubectl}/bin/kubectl --kubeconfig .kube/admin.kubeconfig $@
  '';
  he = writeShellScriptBin "he" ''
    ${kubernetes-helm}/bin/helm --kubeconfig .kube/admin.kubeconfig $@
  '';
}
