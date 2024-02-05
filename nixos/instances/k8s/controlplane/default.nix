{ lib
, resourcesByRoles
, ...
}:
let
  nodes = map (r: "${r.values.name} ${r.values.ipv4_address}") (resourcesByRoles [ "etcd" "controlplane" "loadbalancer" "worker" ] "k8s");
in
{
  imports = [
    ../../init
    ../autoresources.nix
    ./apiserver.nix
    ./controller-manager.nix
    ./kubelet.nix
    # ./scheduler.nix
  ];
  services.kubernetes.clusterCidr = "10.200.0.0/16";

  networking.extraHosts = lib.concatMapStrings
    (x: x + "\n")
    nodes;
}
