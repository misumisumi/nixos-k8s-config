{ lib
, inputs
, stateVersion
, ...
}:
with lib; let
  user = "nixos";
  system = "x86_64-linux";

  inherit (import ../../utils/resources.nix { inherit lib; }) resourcesByRole machineType;

  controlPlaneHosts = map (r: r.values.name) (resourcesByRole "controlplane" "k8s");
  etcdHosts = map (r: r.values.name) (resourcesByRole "etcd" "k8s");
  loadBalancerHosts = map (r: r.values.name) (resourcesByRole "loadbalancer" "k8s");
  workerHosts = map (r: r.values.name) (resourcesByRole "worker" "k8s");
  # nfsHosts = map (r: r.values.name) (resourcesByRole "nfs" "nfs");
  # netbootHosts = map (r: r.values.name) (resourcesByRole "netboot" "netboot");

  specialArgs = { inherit stateVersion inputs user; };

in
{
  lxc-container = nixosSystem {
    inherit system specialArgs;
    modules = [
      ./init/modules.nix
      ./lxd/container
    ];
  };
  lxc-virtual-machine = nixosSystem {
    inherit system specialArgs;
    modules = [
      ./init/modules.nix
      ./lxd/virtual-machine
    ];
  };
}
// builtins.listToAttrs
  (map
    (h: {
      name = h;
      value = nixosSystem {
        inherit system specialArgs;
        modules = [
          ./k8s/controlplane
          ./lxd/${machineType "controlplane" "k8s"}
        ];
      };
    })
    controlPlaneHosts
  )
// builtins.listToAttrs
  (map
    (h: {
      name = h;
      value = nixosSystem {
        inherit system specialArgs;
        modules = [
          ./k8s/etcd
          ./lxd/${machineType "etcd" "k8s"}
        ];
      };
    })
    etcdHosts)
// builtins.listToAttrs
  (map
    (h: {
      name = h;
      value = nixosSystem {
        inherit system specialArgs;
        modules = [
          ./k8s/loadbalancer
          ./lxd/${machineType "loadbalancer" "k8s"}
        ];
      };
    })
    loadBalancerHosts)
  // builtins.listToAttrs
  (map
    (h: {
      name = h;
      value = nixosSystem {
        inherit system specialArgs;
        modules = [
          ./k8s/worker
          ./lxd/${machineType "worker" "k8s"}
        ];
      };
    })
    workerHosts)
