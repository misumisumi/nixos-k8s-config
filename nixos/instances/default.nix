{
  lib,
  inputs,
  self,
  ...
}:
with lib;
let
  user = "nixos";
  system = "x86_64-linux";

  inherit (import ../../utils/resources.nix { inherit lib; }) resourcesByRole machineType;

  controlPlaneHosts = map (r: r.values.name) (resourcesByRole "controlplane" "k8s");
  etcdHosts = map (r: r.values.name) (resourcesByRole "etcd" "k8s");
  loadBalancerHosts = map (r: r.values.name) (resourcesByRole "loadbalancer" "k8s");
  workerHosts = map (r: r.values.name) (resourcesByRole "worker" "k8s");
  # nfsHosts = map (r: r.values.name) (resourcesByRole "nfs" "nfs");
  netbootHosts = map (r: r.values.name) (resourcesByRole "ipxe-server" "ipxe-server");

  specialArgs = {
    inherit inputs self user;
  };

in
{
  lxc-container = nixosSystem {
    inherit system specialArgs;
    modules = [
      ./init/modules.nix
      ./incus/container
    ];
  };
  virtual-machine = nixosSystem {
    inherit system specialArgs;
    modules = [
      ./init/modules.nix
      ./incus/virtual-machine
    ];
  };
}
// builtins.listToAttrs (
  map (h: {
    name = h;
    value = nixosSystem {
      inherit system specialArgs;
      modules = [
        ./k8s/controlplane
        ./lxd/${machineType "controlplane" "k8s"}
      ];
    };
  }) controlPlaneHosts
)
// builtins.listToAttrs (
  map (h: {
    name = h;
    value = nixosSystem {
      inherit system specialArgs;
      modules = [
        ./k8s/etcd
        ./lxd/${machineType "etcd" "k8s"}
      ];
    };
  }) etcdHosts
)
// builtins.listToAttrs (
  map (h: {
    name = h;
    value = nixosSystem {
      inherit system specialArgs;
      modules = [
        ./k8s/loadbalancer
        ./lxd/${machineType "loadbalancer" "k8s"}
      ];
    };
  }) loadBalancerHosts
)
// builtins.listToAttrs (
  map (h: {
    name = h;
    value = nixosSystem {
      inherit system specialArgs;
      modules = [
        ./k8s/worker
        ./lxd/${machineType "worker" "k8s"}
      ];
    };
  }) workerHosts
)
// builtins.listToAttrs (
  map (h: {
    name = h;
    value = nixosSystem {
      inherit system specialArgs;
      modules = [
        ./ipxe-server
        ./incus/${machineType "ipxe-server" "ipxe-server"}
      ];
    };
  }) netbootHosts
)
