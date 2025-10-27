{
  lib,
  callPackage,
  jq,
  kubectl,
  kubernetes-helm,
  nixos-generators,
  ssh-to-age,
  terraform,
  writeShellScriptBin,
}:
{
  check-k8s = callPackage ./check-k8s.nix { };
  deploy = callPackage ./deploy.nix { };
  mkenv = callPackage ./mkenv.nix { };
  mksshhostkeys = callPackage ./mksshhostkeys.nix { };
  ter = callPackage ./ter.nix { };
  k = writeShellScriptBin "k" ''
    ${kubectl}/bin/kubectl --kubeconfig .kube/admin.kubeconfig $@
  '';
  he = writeShellScriptBin "he" ''
    ${kubernetes-helm}/bin/helm --kubeconfig .kube/admin.kubeconfig $@
  '';
  check-disk-size = writeShellScriptBin "check-disk-size" ''
    lsblk -b -io KNAME,TYPE,SIZE,MODEL | awk 'BEGIN{OFS="\t"; OFMT="%.1f"; print "KNAME","TYPE","SIZE","MODEL";} $2 == "disk" {if (FNR>1) print $1,$2,int($3/1073741824)"G",$4; else print $0}'
  '';
  mkkeyfile = writeShellScriptBin "mkkeyfile" ''

  '';
}
// (callPackage ./setup-lxd.nix { })
// (callPackage ./mkage.nix { })
