{ lib
, resourcesByRoles
, ...
}:
let
  nodes = map (r: "${r.values.name} ${r.values.ip_address}") (resourcesByRoles [ "etcd" "controlplane" "loadbalancer" "worker" ] "k8s");
in
{
  imports = [
    ../../init
    ../autoresources.nix
    ../node
    ./apiserver.nix
    ./controller-manager.nix
    ./hive.nix
    ./kubelet.nix
    ./scheduler.nix
  ];
  services.kubernetes.clusterCidr = "10.200.0.0/16";

  networking.extraHosts = lib.concatMapStrings
    (x: x + "\n")
    nodes;
}
