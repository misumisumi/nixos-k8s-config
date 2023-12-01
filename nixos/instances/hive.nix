{ inputs
, stateVersion
, nixosConfigurations
,
}:
let
  inherit (inputs.nixpkgs) lib;
  inherit (import ../utils/resources.nix { inherit lib; }) resourcesByRole;

  etcdHosts = map (r: r.values.name) (resourcesByRole "etcd" "k8s");
  controlPlaneHosts = map (r: r.values.name) (resourcesByRole "controlplane" "k8s");
  workerHosts = map (r: r.values.name) (resourcesByRole "worker" "k8s");
  loadBalancerHosts = map (r: r.values.name) (resourcesByRole "loadbalancer" "k8s");
  nfsHosts = map (r: r.values.name) (resourcesByRole "nfs" "nfs");
  netbootHosts = map (r: r.values.name) (resourcesByRole "netboot" "netboot");
  machineType = target: tag: builtins.head (map (r: r.values.type) (resourcesByRole target tag));

  etcdConf = { ... }: {
    imports = [ ./init ./k8s/etcd inputs.lxd-nixos.nixosModules.${ machineType "etcd" "k8s"} ];
    deployment.tags = [ "cardinal" "k8s" "etcd" ];
  };

  controlPlaneConf = { ... }: {
    imports = [ ./init ./k8s ./k8s/controlplane inputs.lxd-nixos.nixosModules.${ machineType "controlplane" "k8s"} ];
    deployment.tags = [ "cardinal" "k8s" "controlplane" ];
  };

  workerConf = { ... }: {
    imports = [ ./init ./k8s ./k8s/worker inputs.lxd-nixos.nixosModules.${ machineType "worker" "k8s"} ];
    deployment.tags = [ "cardinal" "k8s" "worker" ];
  };

  loadBalancerConf = { ... }: {
    imports = [ ./init ./k8s ./k8s/loadbalancer inputs.lxd-nixos.nixosModules.${ machineType "loadbalancer" "k8s"} ];
    deployment.tags = [ "cardinal" "k8s" "loadbalancer" ];
  };

  netbootConf = { name, ... }: {
    imports = [ ./init ./netboot inputs.lxd-nixos.nixosModules.${ machineType "netboot" "netboot"} ];
    deployment.tags = [ "cardinal" "netboot" "${ name}" ];
  };

  nfsConf = { name, ... }: {
    imports = [ ./init ./nfs inputs.sops-nix.nixosModules.sops inputs.lxd-nixos.nixosModules.${ machineType "nfs" "nfs"} ];
    deployment.tags = [ "cardinal" "nfs" "${ name}" ];
  };
in
{
  meta = {
    allowApplyAll = false; # Due to mixed configuration of physical nodes and virtual machines
    nixpkgs =
      let
        nixpkgs-unstable = import inputs.nixpkgs-unstable {
          system = "x86_64-linux";
          config = { allowUnfree = true; };
        };
      in
      import inputs.nixpkgs {
        system = "x86_64-linux";
        overlays = [
          inputs.flakes.overlays.default
          (import ../patches { inherit nixpkgs-unstable; })
        ];
      };
    specialArgs = {
      inherit inputs;
      inherit stateVersion;
      inherit nixosConfigurations;
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
