{ hostname
, pkgs
, ...
}:
let
  inherit (pkgs.callPackage ../../../utils/resources.nix { }) resourcesFromHosts;
  ip_address = (builtins.head (builtins.filter (v: v.name == hostname) resourcesFromHosts)).ip_address;
in
{
  networking = {
    wireless = {
      enable = false;
    };
  };
  networking.interfaces.enp2s0 = {
    wakeOnLan.enable = true;
    useDHCP = false;
  };
  boot.initrd.availableKernelModules = [ "r8169" ];
  boot.initrd.network.udhcpc.extraArgs = [
    "-i"
    "enp2s0"
    "-r"
    "${ip_address}"
  ];
  systemd = {
    network = {
      netdevs = {
        "br0".netdevConfig = {
          Kind = "bridge";
          Name = "br0";
        };
      };
      networks = {
        "10-wired" = {
          name = "enp2s0";
          bridge = [ "br0" ];
        };
        "20-br0" = {
          name = "br0";
          DHCP = "yes";
          address = [ "${ip_address}" ];
        };
      };
    };
  };
}
