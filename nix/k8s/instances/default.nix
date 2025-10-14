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

  inherit (import ../modules/lib/tf_state.nix { inherit lib; }) resourcesByRole machineType;

  controlPlaneHosts = map (r: r.values.name) (resourcesByRole "controlplane" "k8s");
  etcdHosts = map (r: r.values.name) (resourcesByRole "etcd" "k8s");
  loadBalancerHosts = map (r: r.values.name) (resourcesByRole "loadbalancer" "k8s");
  workerHosts = map (r: r.values.name) (resourcesByRole "worker" "k8s");
  netbootHosts = map (r: r.values.name) (resourcesByRole "ipxe-server" "ipxe-server");

  specialArgs = {
    inherit inputs self user;
  };

in
{
  lxc-container = nixosSystem {
    inherit system specialArgs;
    modules = [
      ./_init/settings
      ./_init/incus/container
    ];
  };
  virtual-machine = nixosSystem {
    inherit system specialArgs;
    modules = [
      ./init/settings
      ./init/incus/virtual-machine
    ];
  };
}
// builtins.listToAttrs (
  map (h: {
    name = h;
    value = nixosSystem {
      inherit system specialArgs;
      modules = [
        ./_init/incus/${machineType "controlplane" "k8s"}
        ./_init/settings
        ./k8s/nix/controlplane
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
        ./_init/incus/${machineType "etcd" "k8s"}
        ./_init/settings
        ./k8s/nix/etcd
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
        ./_init/incus/${machineType "loadbalancer" "k8s"}
        ./_init/settings
        ./k8s/nix/loadbalancer
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
        ./init/incus/${machineType "worker" "k8s"}
        ./init/settings
        ./k8s/nix/worker
      ];
    };
  }) workerHosts
)
