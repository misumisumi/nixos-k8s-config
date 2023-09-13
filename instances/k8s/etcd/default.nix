{ lib
, resourcesByRole
, resourcesByRoles
, nodeIP
, workspace
, ...
}:
let
  pwd = builtins.toPath (builtins.getEnv "PWD");
  cluster = lib.mapAttrsToList (r: "${r.values.name}=https://${r.values.ip_address}:2380") (resourcesByRole "etcd" "k8s");
  nodes = lib.mapAttrsToList (r: "${r.values.name} ${r.values.ip_address}") (resourcesByRoles [ "etcd" "controlplane" "loadbalancer" "worker" ] "k8s");

  mkSecret = filename: {
    keyFile = "${pwd}/.kube/${workspace}/etcd" + "/${filename}";
    destDir = "/var/lib/secrets/etcd";
    user = "etcd";
  };
in
{
  # For colmena
  deployment.keys = {
    "ca.pem" = mkSecret "ca.pem";
    "peer.pem" = mkSecret "peer.pem";
    "peer-key.pem" = mkSecret "peer-key.pem";
    "server.pem" = mkSecret "server.pem";
    "server-key.pem" = mkSecret "server-key.pem";
  };

  networking.firewall.allowedTCPPorts = [ 2379 2380 ];
  networking.extraHosts = lib.strings.concatMapStrings (x: x + "\n") nodes;

  services.etcd = {
    enable = true;

    advertiseClientUrls = [ "https://${nodeIP}:2379" ];
    initialAdvertisePeerUrls = [ "https://${nodeIP}:2380" ];
    initialCluster = lib.mkForce cluster;
    listenClientUrls = [ "https://${nodeIP}:2379" "https://127.0.0.1:2379" ];
    listenPeerUrls = [ "https://${nodeIP}:2380" "https://127.0.0.1:2380" ];

    clientCertAuth = true;
    peerClientCertAuth = true;

    certFile = "/var/lib/secrets/etcd/server.pem";
    keyFile = "/var/lib/secrets/etcd/server-key.pem";

    peerCertFile = "/var/lib/secrets/etcd/peer.pem";
    peerKeyFile = "/var/lib/secrets/etcd/peer-key.pem";

    peerTrustedCaFile = "/var/lib/secrets/etcd/ca.pem";
    trustedCaFile = "/var/lib/secrets/etcd/ca.pem";
  };

  systemd.services.etcd = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
  };
}