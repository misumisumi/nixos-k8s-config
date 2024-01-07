{ lib
, callPackage
, jq
, kubectl
, kubernetes-helm
, nixos-generators
, ssh-to-age
, terraform
, writeShellScriptBin
,
}:
{
  check-k8s = callPackage (import ./check-k8s.nix) { };
  deploy = callPackage (import ./deploy.nix) { };
  mkenv = callPackage (import ./mkenv.nix) { };
  mksshhostkeys = callPackage (import ./mksshhostkeys.nix) { };
  ter = callPackage (import ./ter.nix) { };
  k = writeShellScriptBin "k" ''
    ${kubectl}/bin/kubectl --kubeconfig .kube/admin.kubeconfig $@
  '';
  he = writeShellScriptBin "he" ''
    ${kubernetes-helm}/bin/helm --kubeconfig .kube/admin.kubeconfig $@
  '';
  mkkeyfile = writeShellScriptBin "mkkeyfile" ''

  '';
} // (callPackage (import ./setup-lxd.nix) { })
  // (callPackage (import ./mkage.nix) { })
