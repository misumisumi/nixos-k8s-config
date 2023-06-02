{
  nixpkgs,
  lib,
}: let
  inherit (import ../../src/resources.nix {inherit lib;}) resourcesByRole;
  inherit (import ../../src/utils.nix) nodeIP;

  etcdHosts = map (r: r.values.name) (resourcesByRole "etcd");
  controlPlaneHosts = map (r: r.values.name) (resourcesByRole "controlplane");
  workerHosts = map (r: r.values.name) (resourcesByRole "worker");
  loadBalancerHosts = map (r: r.values.name) (resourcesByRole "loadbalancer");

  etcdConf = {...}: {
    imports = [./etcd];
    deployment.tags = ["k8s" "etcd"];
  };

  controlPlaneConf = {...}: {
    imports = [./controlplane];
    deployment.tags = ["k8s" "controlplane"];
  };

  workerConf = {...}: {
    imports = [./worker];
    deployment.tags = ["k8s" "worker"];
  };

  loadBalancerConf = {...}: {
    imports = [./loadbalancer];
    deployment.tags = ["k8s" "loadbalancer"];
  };
in
  {
    meta = {
      nixpkgs = import nixpkgs {
        system = "x86_64-linux";
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