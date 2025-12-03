{
  default = {
    imports = [
      ./kexec.nix
      ./netboot.nix
      ./static.nix
      ./tgtd.nix
      ./vfio.nix
      ./virtualisation.nix
    ];
  };
  multiple-dnsmasq = {
    imports = [ ./multiple-dnsmasq.nix ];
  };
  kexec = {
    imports = [ ./kexec ];
  };
  netboot = {
    imports = [ ./netboot.nix ];
  };
  static = {
    imports = [ ./static.nix ];
  };
  # config.lib = import ./lib { inherit tag; };
}
