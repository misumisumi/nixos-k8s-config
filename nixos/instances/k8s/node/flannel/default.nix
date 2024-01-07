{ config
, resourcesByRole
, ...
}:
let
  etcdServers = map (r: "https://${r.values.name}:2379") (resourcesByRole "etcd" "k8s");
in
{
  # https://github.com/NixOS/nixpkgs/blob/145084f62b6341fc4300ba3f8eb244d594168e9d/nixos/modules/services/cluster/kubernetes/flannel.nix#L41-L47
  networking.dhcpcd.denyInterfaces = [ "flannel*" ];
  networking.firewall.allowedUDPPorts = [
    8285 # flannel udp
    8472 # flannel vxlan
  ];
  networking.firewall.trustedInterfaces = [ "flannel*" ];

  services.flannel = {
    enable = true;
    network = config.services.kubernetes.clusterCidr;

    storageBackend = "etcd"; # TODO: reconsider
    etcd = {
      endpoints = etcdServers;

      caFile = "/var/lib/secrets/flannel/etcd-ca.pem";
      certFile = "/var/lib/secrets/flannel/etcd-client.pem";
      keyFile = "/var/lib/secrets/flannel/etcd-client-key.pem";
    };
  };

  # systemd.network module makes this true by default, however:
  # https://github.com/NixOS/nixpkgs/issues/114118
  services.resolved.enable = false;

  services.kubernetes.kubelet = {
    cni.config = [
      {
        name = "mynet";
        type = "flannel";
        cniVersion = "0.3.1";
        delegate = {
          isDefaultGateway = true;
          bridge = "mynet";
        };
      }
    ];
  };
}
