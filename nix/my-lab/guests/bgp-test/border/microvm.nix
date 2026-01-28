{ ... }:
{
  microvm.vms = {
    router = {
      config = {
        # It is highly recommended to share the host's nix-store
        # with the VMs to prevent building huge images.
        microvm = {
          registerWithMachined = true;
          vcpu = 2;
          mem = 2048; # in MB
          vsock = {
            cid = 1337;
            ssh.enable = true;
          };
          shares = [
            {
              source = "/nix/store";
              mountPoint = "/nix/.ro-store";
              tag = "ro-store";
              proto = "virtiofs";
            }
          ];
          interfaces = [
            {
              type = "macvtap";
              id = "vm_10g";
              mac = "20:00:00:00:00:02";
              macvtap = {
                link = "enp5s0";
                mode = "bridge";
              };
            }
            {
              type = "macvtap";
              id = "vm_40g";
              mac = "20:00:00:00:00:02";
              macvtap = {
                link = "enp6s0";
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
