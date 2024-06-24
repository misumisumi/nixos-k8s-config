{ hostname, ... }: {
  services = {
    nscd = {
      enable = true;
    };
  };
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
        "incusbr0"
      ];
    };
  };

  systemd = {
    network = {
      netdevs = {
        "br0".netdevConfig = {
          Kind = "bridge";
          Name = "br0";
          MACAddress = "2e:d4:f0:29:dd:28";
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
