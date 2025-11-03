{
  default = {
    imports = [
      ./kexec.nix
      ./netboot.nix
      ./tgtd.nix
      ./vfio.nix
      ./virtualisation.nix
    ];
  };
  multiple-dnsmasq = {
    imports = [ ./multiple-dnsmasq.nix ];
  };
  kexec = {
    imports = [ ./kexec.nix ];
  };
  netboot = {
    imports = [ ./netboot.nix ];
  };
  # config.lib = import ./lib { inherit tag; };
}
