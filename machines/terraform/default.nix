{
  nixpkgs,
  callPackage,
  ...
}: let
  inherit (callPackage ../src/resources.nix {}) resources resourcesByRole;
  inherit (import ../src/utils.nix) nodeIP;

  etcdHosts = map (r: r.values.name) (resourcesByRole "etcd");
  controlPlaneHosts = map (r: r.values.name) (resourcesByRole "controlplane");
  workerHosts = map (r: r.values.name) (resourcesByRole "worker");
  loadBalancerHosts = map (r: r.values.name) (resourcesByRole "loadbalancer");

  etcdConf = {...}: {
    imports = [./etcd];
    deployment.tags = ["etcd"];
  };

  controlPlaneConf = {...}: {
    imports = [./controlplane];
    deployment.tags = ["controlplane"];
  };

  workerConf = {...}: {
    imports = [./worker];
    deployment.tags = ["worker"];
  };

  loadBalancerConf = {...}: {
    imports = [./loadbalancer];
    deployment.tags = ["loadbalancer"];
  };
in
  {
    meta = {
      inherit nixpkgs;
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

      system.stateVersion = "22.05";
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