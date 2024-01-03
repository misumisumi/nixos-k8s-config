{ lib
, nixosConfigurations
}:
let
  inherit (import ../../utils/resources.nix { inherit lib; }) resourcesByRole machineType;

  etcdHosts = map (r: r.values.name) (resourcesByRole "etcd" "k8s");
  controlPlaneHosts = map (r: r.values.name) (resourcesByRole "controlplane" "k8s");
  workerHosts = map (r: r.values.name) (resourcesByRole "worker" "k8s");
  loadBalancerHosts = map (r: r.values.name) (resourcesByRole "loadbalancer" "k8s");
  nfsHosts = map (r: r.values.name) (resourcesByRole "nfs" "nfs");
  netbootHosts = map (r: r.values.name) (resourcesByRole "netboot" "netboot");

  controlPlaneConf = {
    imports = [ ./k8s/controlplane ./lxd/${machineType "controlplane" "k8s"} ];
  };

  etcdConf = {
    imports = [ ./k8s/etcd ./lxd/${machineType "etcd" "k8s"} ];
  };

  loadBalancerConf = {
    imports = [ ./k8s/loadbalancer ./lxd/${machineType "loadbalancer" "k8s"} ];
  };

  workerConf = {
    imports = [ ./k8s/worker ./lxd/${machineType "worker" "k8s"} ];
  };
  # { ... }: {
  #   imports = [ ./init ./k8s ./k8s/worker ./lxd/${machineType "worker" "k8s"} ];
  #   deployment.tags = [ "cardinal" "k8s" "worker" ];
  # };

  # netbootConf = { name, ... }: {
  #   imports = [ ./init ./netboot ./lxd/${machineType "netboot" "netboot"} ];
  #   deployment.tags = [ "cardinal" "netboot" "${name}" ];
  # };

  # nfsConf = { name, ... }: {
  #   imports = [ ./init ./nfs ./lxd/${machineType "nfs" "nfs"} ];
  #   deployment.tags = [ "cardinal" "nfs" "${name}" ];
  # };
in
builtins.listToAttrs
  (map
    (h: {
      name = h;
      value = controlPlaneConf;
    })
    controlPlaneHosts)
// builtins.listToAttrs
  (map
    (h: {
      name = h;
      value = etcdConf;
    })
    etcdHosts)
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
# // builtins.listToAttrs (map
#   (h: {
#     name = h;
#     value = nfsConf;
#   })
#   nfsHosts)
# // builtins.listToAttrs (map
#   (h: {
#     name = h;
#     value = netbootConf;
#   })
#   netbootHosts)

