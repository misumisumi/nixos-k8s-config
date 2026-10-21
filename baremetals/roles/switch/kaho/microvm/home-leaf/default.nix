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
  hostIFaces = static.switch.kaho.networks;
in
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
        cid = 1339;
        ssh.enable = true;
      };
      shares = [
        {
          source = "/nix/store";
          mountPoint = "/nix/.ro-store";
          tag = "home-leaf-ro-store";
          proto = "virtiofs";
        }
      ];
      interfaces = [
        {
          type = "tap";
          id = "vm_home2host";
          mac = "20:20:00:00:00:aa";
          tap.vhost = true;
        }
        {
          type = "macvtap";
          id = "vm_leaf2ap";
          mac = "20:20:00:00:00:ab";
          macvtap = {
            link = hostIFaces.intra10G_1.IF;
            mode = "passthru";
          };
        }
        {
          type = "macvtap";
          id = "vm_leaf2home40g";
          mac = "20:20:00:00:00:ac";
          macvtap = {
            link = hostIFaces.intra40G_4.IF;
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
      ./containers/kea.nix
    ];
  };
}
