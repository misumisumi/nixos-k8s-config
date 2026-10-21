{
  self,
  lib,
  inputs,
  isDev,
  isNixOSTest,
  user,
  static,
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
      mem = 1024 * 4; # in MB
      vsock = {
        cid = 1340;
        ssh.enable = true;
      };
      shares = [
        {
          source = "/nix/store";
          mountPoint = "/nix/.ro-store";
          tag = "svc-leaf-ro-store";
          proto = "virtiofs";
        }
      ];
      interfaces = [
        {
          type = "tap";
          id = "vm_svc2host";
          mac = "20:30:00:00:00:aa";
          tap.vhost = true;
        }
      ];
    };
    imports = [
      ../../../../share/modules/static.nix
      ../../../../share/apps/debug.nix
      ../share
      ./bgp.nix
      ./network.nix
      ./containers/unbound.nix
    ];
  };
}
