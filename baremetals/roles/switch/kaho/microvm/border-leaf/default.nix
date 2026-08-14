{
  self,
  lib,
  inputs,
  isDev,
  isNixOSTest,
  user,
}:
{
  specialArgs = {
    inherit
      self
      lib
      inputs
      user
      isDev
      isNixOSTest
      ;
  };
  extraModules = [
    inputs.homelab-modules.nixosModules.vlan-aware-vxlan
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
            link = if isDev then "enp7s0" else "enp4s0f1";
            mode = "passthru";
          };
        }
      ];
    };
    imports = [
      ../../../../share/modules/static.nix
      ../../../../share/apps/debug.nix
      ../share
      ./bgp.nix
      ./network.nix
    ];
  };
}
