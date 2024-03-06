{ hostname, ... }:
let
  interfaceName = "enp1s0";
in
{
  services = {
    nscd = {
      enable = true;
    };
  };
  boot.initrd.network.udhcpc.extraArgs = [
    "-i"
    "${interfaceName}"
  ];
  networking = {
    hostName = "${hostname}";
    interfaces.${interfaceName}.wakeOnLan.enable = true;
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
          MACAddress = "71:9a:a2:fa:05:38";
        };
      };
      networks = {
        "10-wired" = {
          name = "enp1s0";
          bridge = [ "br0" ];
        };
        "20-br0" = {
          name = "br0";
          DHCP = "yes";
        };
      };
    };
  };
}
