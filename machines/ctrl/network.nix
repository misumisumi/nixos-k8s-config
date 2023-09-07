{ hostname, ... }:
let
  interface = "enp2s0";
in
{
  imports = [
    ../common/network.nix
  ];
  services = {
    nscd = {
      enable = true;
    };
  };
  boot.initrd.availableKernelModules = [ "r8169" ];
  boot.initrd.network.udhcpc.extraArgs = [
    "-i"
    "${interface}"
  ];
  networking = {
    hostName = "${hostname}";
    interfaces.${interface}.wakeOnLan.enable = true;
    firewall = {
      enable = true;
      trustedInterfaces = [
        "br0"
        "br1"
        "lxdbr0"
        "k8sbr0"
      ];
    };
  };

  systemd = {
    network = {
      netdevs = {
        "br0".netdevConfig = {
          Kind = "bridge";
          Name = "br0";
        };
        # "br1".netdevConfig = {
        #   Kind = "bridge";
        #   Name = "br1";
        # };
      };
      networks = {
        "10-wired" = {
          name = "${interface}";
          bridge = [ "br0" ];
        };
        "20-br0" = {
          name = "br0";
          address = [ "192.168.1.101/24" ];
          gateway = [ "192.168.1.254" ];
        };
      };
    };
  };
}
