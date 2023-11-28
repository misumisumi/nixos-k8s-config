{ ws
, callPackage
, cfssl
, kubectl
,
}:
let
  inherit (callPackage ./utils/utils.nix { }) getAltNames mkCsr;

  caCsr = mkCsr "flannel-ca" { cn = "flannel-ca"; };
  etcdClientCsr = mkCsr "etcd-client" {
    cn = "flannel";
    altNames = getAltNames "worker" ws;
  };
in
''
  mkdir -p $out/${ws}/flannel

  pushd $out/${ws}/etcd > /dev/null
  genCert client ../flannel/etcd-client ${etcdClientCsr}
  popd > /dev/null
''
