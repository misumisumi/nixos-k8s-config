{ hostname, ... }: {
  services = {
    nscd = {
      enable = true;
    };
  };
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
          MACAddress = "2e:0a:4f:3c:49:5e";
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
