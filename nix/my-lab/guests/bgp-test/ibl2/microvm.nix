{ ... }:
{
  systemd.network = {
    netdevs = {
      bridge4border = {
        netdevConfig = {
          Name = "bridge4border";
          Kind = "bridge";
          Description = "Bridge for border leaf VM";
        };
      };
    };
    networks = {
      "15-bridge4border" = {
        name = "bridge4border";
        networkConfig = {
          IPv6LinkLocalAddressGenerationMode = "none";
        };
      };
      "16-border-network" = {
        bridge = [ "bridge4border" ];
        matchConfig = {
          Name = [ "vm_border*" ];
        };
      };
    };
  };
  microvm.vms = {
    borderLeaf = {
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
              type = "macvtap";
              id = "vm_40g";
              mac = "20:00:00:00:00:40";
              macvtap = {
                link = "enp6s0";
                mode = "bridge";
              };
            }
            {
              type = "macvtap";
              id = "vm_10g";
              mac = "20:00:00:00:00:10";
              macvtap = {
                link = "enp7s0";
                mode = "passthru";
              };
            }
            {
              type = "tap";
              id = "vm_borderLeaf";
              mac = "20:00:00:00:00:aa";
            }
          ];
        };
        imports = [ ./border-leaf ];
      };
    };
    router = {
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
              mac = "20:10:00:00:00:01";
            }
            {
              type = "macvtap";
              id = "vm_wan";
              mac = "20:10:00:00:00:02";
              macvtap = {
                link = "enp8s0";
                mode = "bridge";
              };
            }
          ];
        };
        imports = [ ./router ];
      };
    };
  };
}
