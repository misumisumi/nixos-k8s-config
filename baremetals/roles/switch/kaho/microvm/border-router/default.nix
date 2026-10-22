{
  self,
  lib,
  inputs,
  isDev,
  isNixOSTest,
  user,
  static,
}:
let
  inherit (lib) optional;
in
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
  extraModules = [
    inputs.homelab-modules.nixosModules.vlan-aware-vxlan
  ];
  config = {
    # It is highly recommended to share the host's nix-store
    # cith the VMs to prevent building huge images.
    microvm = {
      registerWithMachined = true;
      vcpu = 2;
      mem = 1024 * 4; # in MB
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
        {
          source = "/var/lib/secrets/wireguard";
          mountPoint = "/var/lib/secrets/wireguard";
          tag = "router-wireguard-secrets";
          proto = "virtiofs";
        }
      ];
      interfaces = [
        {
          type = "tap";
          id = "vm_router2host";
          mac = "20:10:00:00:00:aa";
          tap.vhost = true;
        }
      ];
    };
    imports = [
      ../../../../share/modules/static.nix
      ../../../../share/apps/debug.nix
      ../share
      (if isDev then ./develop else ./production)
      ./bgp.nix
      ./network.nix
      ./nftables.nix
      ./v6plus.nix
    ];
    # ++ optional (!isDev) ./wireguard.nix;
  };
}
