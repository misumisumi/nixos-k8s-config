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
  check_k8s = callPackage (import ./check_k8s.nix) { };
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
  mkimg4lxc = writeShellScriptBin "mkimg4lxc" ''
    nix run ".#import/lxc-container" --impure
    nix run ".#import/lxc-virtual-machine" --impure
  '';
  init_nfs_instance = writeShellScriptBin "init_nfs_instance" ''
    deploy exec nfs -w development -- drbdadm create-md r0
    deploy exec nfs -w development -- drbdadm up r0
    # deploy exec nfs1 -w development -- drbdadm primary r0 --force
  '';
} // (callPackage (import ./setup_lxd.nix) { })
  // (callPackage (import ./mkage.nix) { })

