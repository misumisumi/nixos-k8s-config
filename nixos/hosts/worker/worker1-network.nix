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
          name = "eno1";
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
