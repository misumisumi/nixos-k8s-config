{ lib
, nodeIP
, resourcesByRole
, resourcesByRoles
, ...
}:
let
  etcdServers = map (r: "${r.values.name}=https://${r.values.ip_address}:2380") (resourcesByRole "etcd" "k8s");
  nodes = map (r: "${r.values.name} ${r.values.ip_address}") (resourcesByRoles [ "etcd" "controlplane" "loadbalancer" "worker" ] "k8s");
in
{
  imports = [
    ../../init
    ../autoresources.nix
  ];

  networking.firewall.allowedTCPPorts = [ 2379 2380 ];
  networking.extraHosts = lib.strings.concatMapStrings (x: x + "\n") nodes;

  services.etcd = {
    enable = true;

    advertiseClientUrls = [ "https://${nodeIP}:2379" ];
    initialAdvertisePeerUrls = [ "https://${nodeIP}:2380" ];
    initialCluster = lib.mkForce etcdServers;
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
