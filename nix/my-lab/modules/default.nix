{
  build = {
    imports = [ ./build.nix ];
  };
  default = {
    imports = [
      ./build.nix
      ./diskless
      ./kexec
      ./netboot.nix
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
  multiple-dnsmasq = {
    imports = [ ./multiple-dnsmasq.nix ];
  };
  netboot = {
    imports = [ ./netboot.nix ];
  };
}
