{
  inputs,
  nixpkgs,
  lib,
}: let
  inherit (import ../../src/resources.nix {inherit lib;}) resourcesByRole;
  inherit (import ../../src/utils.nix) nodeIP;

  etcdHosts = map (r: r.values.name) (resourcesByRole "etcd");
  controlPlaneHosts = map (r: r.values.name) (resourcesByRole "controlplane");
  workerHosts = map (r: r.values.name) (resourcesByRole "worker");
  loadBalancerHosts = map (r: r.values.name) (resourcesByRole "loadbalancer");
  nfsHosts = map (r: r.values.name) (resourcesByRole "nfs");

  etcdConf = {...}: {
    imports = [./k8s/etcd];
    deployment.tags = ["cardinal" "k8s" "etcd"];
  };

  controlPlaneConf = {...}: {
    imports = [./k8s/controlplane];
    deployment.tags = ["cardinal" "k8s" "controlplane"];
  };

  workerConf = {...}: {
    imports = [./k8s/worker];
    deployment.tags = ["cardinal" "k8s" "worker"];
  };

  loadBalancerConf = {...}: {
    imports = [./k8s/loadbalancer];
    deployment.tags = ["cardinal" "k8s" "loadbalancer"];
  };

  nfsConf = {name, ...}: {
    imports = [./nfs];
    deployment.tags = ["cardinal" "nfs" "${name}"];
  };
in
  {
    meta = {
      nixpkgs = import nixpkgs {
        system = "x86_64-linux";
      };
      specialArgs = {
        inherit inputs;
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

      system.stateVersion = "23.05";
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