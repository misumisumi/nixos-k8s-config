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
  mkimg4lxc = writeShellScriptBin "mkimg4lxc" ''
    lxc image import ''$(nixos-generate -f lxc-metadata) ''$(nixos-generate -f lxc --flake ".#lxc-container") --alias nixos/lxc-container
    lxc image import ''$(nixos-generate -f lxc-metadata) ''$(nixos-generate -f qcow --flake ".#lxc-virtual-machine") --alias nixos/lxc-virtual-machine
    lxc image copy images:almalinux/9 local: --auto-update --alias almalinux9/lxc-container
    lxc image copy images:almalinux/9 local: --auto-update --alias almalinux9/lxc-virtual-machine --vm
  '';
} // (callPackage (import ./setup-lxd.nix) { })
  // (callPackage (import ./mkage.nix) { })
