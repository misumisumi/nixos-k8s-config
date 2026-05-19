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
    borderLeaf = {
      specialArgs = {
        inherit
          self
          inputs
          user
          isDev
          isNixOSTest
          ;
      };
      extraModules = [
        self.nixosModules.vlan-aware-vxlan
      ];
      config = {
        # It is highly recommended to share the host's nix-store
        # with the VMs to prevent building huge images.
        microvm = {
          registerWithMachined = true;
          vcpu = 2;
          mem = 1024 * 3; # in MB
          vsock = {
            cid = 1337;
            ssh.enable = true;
          };
          shares = [
            {
              source = "/nix/store";
              mountPoint = "/nix/.ro-store";
              tag = "border-leaf-ro-store";
              proto = "virtiofs";
            }
          ];
          interfaces = [
            {
              type = "tap";
              id = "vm_borderLeaf";
              mac = "20:00:00:00:00:aa";
            }
            {
              type = "tap";
              id = "vm_40g";
              mac = "20:00:00:00:00:01";
            }
            {
              type = "macvtap";
              id = "vm_10g";
              mac = "20:00:00:00:00:02";
              macvtap = {
                link = "enp7s0";
                mode = "passthru";
              };
            }
          ];
        };
        imports = [
          ../../../share/modules/static.nix
          ./border-leaf
        ];
      };
    };
    borderRouter = {
      specialArgs = {
        inherit
          self
          inputs
          isDev
          isNixOSTest
          user
          ;
      };
      config = {
        # It is highly recommended to share the host's nix-store
        # with the VMs to prevent building huge images.
        microvm = {
          registerWithMachined = true;
          vcpu = 2;
          mem = 1024 * 3; # in MB
          vsock = {
            cid = 1338;
            ssh.enable = true;
          };
          shares = [
            {
              source = "/nix/store";
              mountPoint = "/nix/.ro-store";
              tag = "router-ro-store";
              proto = "virtiofs";
            }
          ];
          interfaces = [
            {
              type = "tap";
              id = "vm_borderRouter";
              mac = "20:10:00:00:00:aa";
            }
            {
              type = "macvtap";
              id = "vm_wan";
              mac = "20:10:00:00:00:01";
              macvtap = {
                link = "enp5s0";
                mode = "bridge";
              };
            }
          ];
        };
        imports = [
          ../../../share/modules/static.nix
          ./border-router
        ];
      };
    };
  };
}
