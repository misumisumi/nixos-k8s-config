{ ws
, callPackage
, cfssl
,
}:
let
  inherit (callPackage ./utils/utils.nix { }) getAltNames mkCsr;

  caCsr = mkCsr "etcd-ca" { cn = "etcd-ca"; };
  serverCsr = mkCsr "etcd-server" {
    cn = "etcd";
    altNames = getAltNames "etcd" ws;
  };
  peerCsr = mkCsr "etcd-peer" {
    cn = "etcd-peer";
    altNames = getAltNames "etcd" ws;
  };
in
''
  mkdir -p $out/${ws}/etcd

  pushd $out/${ws}/etcd > /dev/null

  genCa ${caCsr}
  genCert server server ${serverCsr}
  genCert peer peer ${peerCsr}

  popd > /dev/null
''

