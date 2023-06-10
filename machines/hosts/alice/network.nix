{
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
          name = "enp5s0";
          bridge = ["br0"];
        };
        "20-br0" = {
          name = "br0";
          dns = ["192.168.1.40" "127.0.0.1"];
          address = ["192.168.1.20"];
          gateway = ["192.168.1.1"];
        };
      };
    };
  };
}