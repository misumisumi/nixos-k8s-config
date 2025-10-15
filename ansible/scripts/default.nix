{
  callPackage,
  writeShellScriptBin,
  jq,
  kubectl,
  kubernetes-helm,
  nixos-generators,
  terraform,
}: let
  inherit (callPackage ../utils/resources.nix {}) resourcesFromHosts;
  sshConfig =
    builtins.map (v: ''
      Host ${v.name}
        HostName ${v.ip_address}
        User root
        Port 22
    '')
    resourcesFromHosts;
in {
  k = writeShellScriptBin "k" ''
    ${kubectl}/bin/kubectl --kubeconfig .kube/admin.kubeconfig $@
  '';
  he = writeShellScriptBin "he" ''
    ${kubernetes-helm}/bin/helm --kubeconfig .kube/admin.kubeconfig $@
  '';
}