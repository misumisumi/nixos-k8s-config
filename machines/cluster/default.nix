{
  inputs,
  stateVersion,
}: let
  inherit (inputs.nixpkgs) lib;
  inherit (import ../../utils/resources.nix {inherit lib;}) resourcesByRole;
  inherit (import ../../utils/utils.nix) nodeIP;

  etcdHosts = map (r: r.values.name) (resourcesByRole "etcd");
  controlPlaneHosts = map (r: r.values.name) (resourcesByRole "controlplane");
  workerHosts = map (r: r.values.name) (resourcesByRole "worker");
  loadBalancerHosts = map (r: r.values.name) (resourcesByRole "loadbalancer");
  nfsHosts = map (r: r.values.name) (resourcesByRole "nfs");
  machineType = target: builtins.head (map (r: r.values.type) (resourcesByRole target));

  etcdConf = {...}: {
    imports = [./k8s/etcd inputs.lxd-nixos.nixosModules.${machineType "etcd"}];
    deployment.tags = ["cardinal" "k8s" "etcd"];
  };

  controlPlaneConf = {...}: {
    imports = [./k8s/controlplane inputs.lxd-nixos.nixosModules.${machineType "controlplane"}];
    deployment.tags = ["cardinal" "k8s" "controlplane"];
  };

  workerConf = {...}: {
    imports = [./k8s/worker inputs.lxd-nixos.nixosModules.${machineType "worker"}];
    deployment.tags = ["cardinal" "k8s" "worker"];
  };

  loadBalancerConf = {...}: {
    imports = [./k8s/loadbalancer inputs.lxd-nixos.nixosModules.${machineType "loadbalancer"}];
    deployment.tags = ["cardinal" "k8s" "loadbalancer"];
  };

  nfsConf = {name, ...}: {
    imports = [./nfs inputs.lxd-nixos.nixosModules.${machineType "nfs"}];
    deployment.tags = ["cardinal" "nfs" "${name}"];
  };
in
  {
    meta = {
      nixpkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
        overlays = [inputs.flakes.overlays.default];
      };
      specialArgs = {
        inherit inputs;
        inherit stateVersion;
      };
    };

    defaults = {
      name,
      self,
      ...
    }: {
      imports = [
        ./init
        ./autoresources.nix
      ];

      deployment.targetHost = nodeIP self;
      networking.hostName = name;
    };
  }
  // builtins.listToAttrs (map (h: {
      name = h;
      value = etcdConf;
    })
    etcdHosts)
  // builtins.listToAttrs (map (h: {
      name = h;
      value = controlPlaneConf;
    })
    controlPlaneHosts)
  // builtins.listToAttrs (map (h: {
      name = h;
      value = loadBalancerConf;
    })
    loadBalancerHosts)
  // builtins.listToAttrs (map (h: {
      name = h;
      value = workerConf;
    })
    workerHosts)
  // builtins.listToAttrs (map (h: {
      name = h;
      value = nfsConf;
    })
    nfsHosts)