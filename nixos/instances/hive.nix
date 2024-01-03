{ lib
, inputs
, stateVersion
, nixosConfigurations
}:
let
  user = "nixos";
  inherit (import ../../utils/resources.nix { inherit lib; }) resourcesByRole machineType;

  controlPlaneHosts = map (r: r.values.name) (resourcesByRole "controlplane" "k8s");
  etcdHosts = map (r: r.values.name) (resourcesByRole "etcd" "k8s");
  loadBalancerHosts = map (r: r.values.name) (resourcesByRole "loadbalancer" "k8s");
  workerHosts = map (r: r.values.name) (resourcesByRole "worker" "k8s");
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

  # netbootConf = { name, ... }: {
  #   imports = [ ./init ./netboot ./lxd/${machineType "netboot" "netboot"} ];
  #   deployment.tags = [ "cardinal" "netboot" "${name}" ];
  # };

  # nfsConf = { name, ... }: {
  #   imports = [ ./init ./nfs ./lxd/${machineType "nfs" "nfs"} ];
  #   deployment.tags = [ "cardinal" "nfs" "${name}" ];
  # };
  specialArgs4k8s = {
    user = "nixos";
    inherit inputs;
    inherit stateVersion;
  };
in
{
  meta = {
    nixpkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
    };
    nodeSpecialArgs = lib.listToAttrs (
      map (name: { inherit name; value = specialArgs4k8s; }) (controlPlaneHosts ++ etcdHosts ++ loadBalancerHosts ++ workerHosts)
    );
  };
}
// builtins.listToAttrs
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

