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
in
  {
    check_k8s = callPackage (import ./check_k8s.nix) {};
    deploy = callPackage (import ./deploy.nix) {};
    mkenv = callPackage (import ./mkenv.nix) {};
    ter = callPackage (import ./ter.nix) {};
    # ter = writeShellScriptBin "ter" ''
    #   ${terraform}/bin/terraform $@ && \
    #     ${terraform}/bin/terraform show -json | ${jq}/bin/jq > show.json
    # '';
    k = writeShellScriptBin "k" ''
      ${kubectl}/bin/kubectl --kubeconfig .kube/admin.kubeconfig $@
    '';
    he = writeShellScriptBin "he" ''
      ${kubernetes-helm}/bin/helm --kubeconfig .kube/admin.kubeconfig $@
    '';
    mkimg4lxc = writeShellScriptBin "mkimg4lxc" ''
      nix run ".#import/lxc-container" --impure
      nix run ".#import/lxc-virtual-machine" --impure
    '';
    mksshconfig = writeShellScriptBin "mksshconfig" ''
      cat <<EOF > ssh_config
      ${builtins.concatStringsSep "\n" sshConfig}
      EOF
    '';
  }
  // (callPackage (import ./setup_lxd.nix) {})
  // (callPackage (import ./mkdisk.nix) {})