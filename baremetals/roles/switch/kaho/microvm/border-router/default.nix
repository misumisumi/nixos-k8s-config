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
  hostIFaces = static.switch.kaho.networks;
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
        {
          source = "/var/lib/secrets/wireguard";
          mountPoint = "/var/lib/secrets/wireguard";
          tag = "router-wireguard-secrets";
          proto = "virtiofs";
        }
      ];
      interfaces = [
        {
          type = "macvtap";
          id = "vm_router2wan";
          mac = "20:10:00:00:00:01";
          macvtap = {
            link = if isDev then "enp5s0" else hostIFaces.wan.IF;
            mode = "bridge";
          };
        }
        {
          type = "tap";
          id = "vm_router2host";
          mac = "20:10:00:00:00:aa";
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
    ]
    ++ optional (!isDev) ./wireguard.nix;
  };
}
