{
  default = {
    imports = [
      ./diskless
      ./kexec
      ./netboot.nix
      ./static.nix
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
  static = {
    imports = [ ./static.nix ];
  };
}
