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
  ipxe = {
    imports = [ ./ipxe.nix ];
  };
  multiple-dnsmasq = {
    imports = [ ./multiple-dnsmasq.nix ];
  };
}
