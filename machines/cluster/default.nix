{ inputs }:
let
  inherit (inputs.nixpkgs) lib;
  inherit (import ../../utils/resources.nix { inherit lib; }) resourcesByRole;

  etcdHosts = map (r: r.values.name) (resourcesByRole "etcd");
  controlPlaneHosts = map (r: r.values.name) (resourcesByRole "controlplane");
  workerHosts = map (r: r.values.name) (resourcesByRole "worker");
  loadBalancerHosts = map (r: r.values.name) (resourcesByRole "loadbalancer");
  nfsHosts = map (r: r.values.name) (resourcesByRole "nfs");
  machineType = target: builtins.head (map (r: r.values.type) (resourcesByRole target));

  etcdConf = { ... }: {
    imports = [ ./init ./k8s/etcd inputs.lxd-nixos.nixosModules.${machineType "etcd"} ];
    deployment.tags = [ "cardinal" "k8s" "etcd" ];
  };

  controlPlaneConf = { ... }: {
    imports = [ ./init ./k8s/controlplane inputs.lxd-nixos.nixosModules.${machineType "controlplane"} ];
    deployment.tags = [ "cardinal" "k8s" "controlplane" ];
  };

  workerConf = { ... }: {
    imports = [ ./init ./k8s/worker inputs.lxd-nixos.nixosModules.${machineType "worker"} ];
    deployment.tags = [ "cardinal" "k8s" "worker" ];
  };

  loadBalancerConf = { ... }: {
    imports = [ ./init ./k8s/loadbalancer inputs.lxd-nixos.nixosModules.${machineType "loadbalancer"} ];
    deployment.tags = [ "cardinal" "k8s" "loadbalancer" ];
  };

  nfsConf = { name, ... }: {
    imports = [ ./init ./nfs inputs.lxd-nixos.nixosModules.${machineType "nfs"} ];
    deployment.tags = [ "cardinal" "nfs" "${name}" ];
  };
in
builtins.listToAttrs
  (map
    (h: {
      name = h;
      value = etcdConf;
    })
    etcdHosts)
// builtins.listToAttrs (map
  (h: {
    name = h;
    value = controlPlaneConf;
  })
  controlPlaneHosts)
// builtins.listToAttrs (map
  (h: {
    name = h;
    value = loadBalancerConf;
  })
  loadBalancerHosts)
// builtins.listToAttrs (map
  (h: {
    name = h;
    value = workerConf;
  })
  workerHosts)
  // builtins.listToAttrs (map
  (h: {
    name = h;
    value = nfsConf;
  })
  nfsHosts)
