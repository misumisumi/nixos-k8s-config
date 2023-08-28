{ inputs
, stateVersion
,
}:
let
  inherit (inputs.nixpkgs) lib;
  inherit (import ../utils/consts.nix { inherit lib; }) workspace constByKey;

  hostNames = target: lib.mapAttrsToList (x: y: x) (lib.filterAttrs (x: y: lib.hasPrefix target x) (constByKey "instanceIPs").${workspace});
  etcdHosts = map (r: r) (hostNames "etcd");
  controlPlaneHosts = map (r: r) (hostNames "controlplane");
  workerHosts = map (r: r) (hostNames "worker");
  loadBalancerHosts = map (r: r) (hostNames "loadbalancer");
  nfsHosts = map (r: r) (hostNames "nfs");
  netbootHosts = map (r: r) (hostNames "netboot");
  machineType = target: (constByKey "machineTypes").${target};

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

  netbootConf = { name, ... }: {
    imports = [ ./init ./netboot inputs.lxd-nixos.nixosModules.${machineType "netboot"} ];
    deployment.tags = [ "cardinal" "netboot" "${name}" ];
  };

  nfsConf = { name, ... }: {
    imports = [ ./init ./nfs inputs.lxd-nixos.nixosModules.${machineType "nfs"} ];
    deployment.tags = [ "cardinal" "nfs" "${name}" ];
  };
in
{
  meta = {
    allowApplyAll = false; # Due to mixed configuration of physical nodes and virtual machines
    nixpkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
      overlays = [ inputs.flakes.overlays.default ];
    };
    specialArgs = {
      inherit inputs;
      inherit stateVersion;
    };
  };
}
  // (builtins.listToAttrs
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
// builtins.listToAttrs (map
  (h: {
    name = h;
    value = netbootConf;
  })
  netbootHosts)
)
