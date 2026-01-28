{
  lib,
  resourcesByRoles,
  ...
}:
let
  nodes = map (r: "${r.values.name} ${r.values.ipv4_address}") (
    resourcesByRoles [
      "etcd"
      "controlplane"
      "loadbalancer"
      "worker"
    ] "k8s"
  );
in
{
  imports = [
    ../_init/core
    ../autoresources.nix
    ./system/apiserver.nix
    ./system/controller-manager.nix
    ./system/kubelet.nix
    # ./scheduler.nix
  ];
  services.kubernetes.clusterCidr = "10.200.0.0/16";

  networking.extraHosts = lib.concatMapStrings (x: x + "\n") nodes;
}
