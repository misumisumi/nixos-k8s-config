{ ws
, callPackage
, cfssl
, kubectl
,
}:
let
  inherit (callPackage ./utils/utils.nix { }) mkCsr;

  corednsKubeCsr = mkCsr "coredns" {
    cn = "system:coredns";
  };
in
''
  mkdir -p $out/${ws}/coredns

  pushd $out/${ws}/kubernetes > /dev/null
  genCert client ../coredns/coredns-kube ${corednsKubeCsr}
  popd > /dev/null
''