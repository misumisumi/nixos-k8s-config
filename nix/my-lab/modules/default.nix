{
  default = {
    imports = [
      ./kexec.nix
      ./multiple-dnsmasq.nix
      ./netboot.nix
      ./tgtd.nix
      ./vfio.nix
      ./virtualisation.nix
    ];
  };
  kexec = {
    imports = [ ./kexec.nix ];
  };
  netboot = {
    imports = [ ./netboot.nix ];
  };
  # config.lib = import ./lib { inherit tag; };
}
