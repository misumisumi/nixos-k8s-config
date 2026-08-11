{
  self,
  inputs,
  isDev,
  isNixOSTest,
  user,
  ...
}:
{
  systemd.network = {
    netdevs = {
      br_leaf2router = {
        netdevConfig = {
          Name = "br_leaf2router";
          Kind = "bridge";
          Description = "Bridge for border leaf VM to border router VM";
        };
      };
      br_leaf2host = {
        netdevConfig = {
          Name = "br_leaf2host";
          Kind = "bridge";
          Description = "Bridge for border leaf VM to host";
        };
      };
    };
    networks = {
      "15-br_leaf2host" = {
        name = "br_leaf2host";
      };
      "16-border2host-network" = {
        bridge = [ "br_leaf2host" ];
        matchConfig = {
          Name = [ "vm_40g" ];
        };
      };
      "20-br_leaf2router" = {
        name = "br_leaf2router";
        networkConfig = {
          IPv6LinkLocalAddressGenerationMode = "none";
        };
      };
      "21-leaf2router-network" = {
        bridge = [ "br_leaf2router" ];
        matchConfig = {
          Name = [
            "vm_borderLeaf"
            "vm_borderRouter"
          ];
        };
      };
    };
  };
  microvm.vms = {
    borderLeaf = import ./border-leaf {
      inherit
        self
        inputs
        isDev
        isNixOSTest
        user
        ;
    };
    borderRouter = import ./border-router {
      inherit
        self
        inputs
        isDev
        isNixOSTest
        user
        ;
    };
  };
}
