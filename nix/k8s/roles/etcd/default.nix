{
  lib,
  inputs,
  static,
  modulesPath,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    flatten
    imap1
    mkForce
    ;
  nodes = flatten (
    map (role: imap1 (i: ip: "${role}${toString i} ${ip}") static.nodes.${role}.nodeIPs) [
      "etcd"
      "controlplane"
      "worker"
    ]
  );
in
{
  imports = [
    ../share/settings
    ./certs.nix
  ];

  image.modules = mkForce {
    lxc = inputs.homelab-modules.nixosModules.lxc-container;
    lxc-metadata = {
      imports = [
        "${modulesPath}/virtualisation/lxc-image-metadata.nix"
        ./etcd.conf.tpl.nix
      ];
    };
  };

  networking = {
    firewall.allowedTCPPorts = [
      2379
      2380
    ];
  };
  networking.extraHosts = concatStringsSep "\n" nodes;

  services.etcd = {
    enable = true;

    # advertiseClientUrls = [ "https://${nodeIP}:2379" ];
    # initialAdvertisePeerUrls = [ "https://${nodeIP}:2380" ];
    # initialCluster = mkForce etcdServers;
    # listenClientUrls = [
    #   "https://${nodeIP}:2379"
    #   "https://127.0.0.1:2379"
    # ];
    # listenPeerUrls = [
    #   "https://${nodeIP}:2380"
    #   "https://127.0.0.1:2380"
    # ];

    # clientCertAuth = true;
    # peerClientCertAuth = true;

    # certFile = "/etc/kubernetes/pki/etcd/server.pem";
    # keyFile = "/etc/kubernetes/pki/etcd/server-key.pem";

    # peerCertFile = "/etc/kubernetes/pki/etcd/peer.pem";
    # peerKeyFile = "/etc/kubernetes/pki/etcd/peer-key.pem";

    # peerTrustedCaFile = "/etc/kubernetes/pki/etcd/ca.pem";
    # trustedCaFile = "/etc/kubernetes/pki/etcd/ca.pem";
    extraConf = {
      CONFIG_FILE = "/etc/etcd.conf";
    };
  };

  systemd.services.etcd = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
  };
}
