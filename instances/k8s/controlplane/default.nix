{ lib
, nodeIPsByRoles
, workspace
, ...
}:
let
  pwd = builtins.toPath (builtins.getEnv "PWD");
  nodes = lib.mapAttrsToList (name: ip: "${name} ${ip}") (nodeIPsByRoles [ "etcd" "controlplane" "loadbalancer" "worker" ]);
in
{
  imports = [
    ./apiserver.nix
    ./controller-manager.nix
    ./scheduler.nix
    ./kubelet.nix
    ../node
  ];

  # For colmena
  deployment.keys."ca.pem" = {
    keyFile = "${pwd}/.kube/${workspace}/kubernetes/ca.pem";
    destDir = "/var/lib/secrets/kubernetes";
    user = "kubernetes";
  };

  services.kubernetes.clusterCidr = "10.200.0.0/16";

  networking.extraHosts = lib.concatMapStrings (x: x + "\n") nodes;
}
