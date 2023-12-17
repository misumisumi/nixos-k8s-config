{ hostname, ... }: {
  services = {
    nscd = {
      enable = true;
    };
  };
  boot.initrd.availableKernelModules = [ "r8169" ];
  boot.initrd.network.udhcpc.extraArgs = [
    "-i"
    "eno1"
  ];
  networking = {
    hostName = "${hostname}";
    interfaces.eno1.wakeOnLan.enable = true;
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
      };
      networks = {
        "10-wired" = {
          name = "eno1";
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
