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
      isDev
      isNixOSTest
      user
      ;
    group = "microvm";
    hostname = "borderRouter";
  };
  config = {
    # It is highly recommended to share the host's nix-store
    # cith the VMs to prevent building huge images.
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
            link = if isDev then "enp5s0" else "enp4s0f0";
            mode = "bridge";
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
      ./nftables.nix
      ./v6plus.nix
      ./wireguard.nix
    ];
  };
}
