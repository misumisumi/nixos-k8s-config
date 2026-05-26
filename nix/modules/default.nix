{
  build = {
    imports = [ ./build.nix ];
  };
  default = {
    imports = [
      ./build.nix
      ./diskless
      ./tgtd.nix
      ./vfio.nix
      ./virtualisation.nix
    ];
  };
  diskless = {
    imports = [ ./diskless ];
  };
  kexec = {
    imports = [ ./kexec ];
  };
  incus-vm = {
    imports = [ ./incus-virtual-machine.nix ];
  };
  ipxe = {
    imports = [ ./ipxe.nix ];
  };
  lxc-container = {
    imports = [ ./lxc-container.nix ];
  };
  multiple-dnsmasq = {
    imports = [ ./multiple-dnsmasq.nix ];
  };
  vlan-aware-vxlan = {
    imports = [ ./vlan-aware-vxlan.nix ];
  };
}
