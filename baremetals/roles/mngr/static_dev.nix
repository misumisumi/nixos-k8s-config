{
  mngr = {
    naokosan = {
      system = "x86_64-linux";
      user = "misuzu";
      hostname = "naokosan";
      networks = {
        manage = {
          IF = "enp5s0";
          address = "192.168.20.30/24";
        };
      };
    };
    "image-server" = {
      system = "x86_64-linux";
      user = "misuzu";
      hostname = "image-server";
      networks = {
        manage = {
          IF = "enp5s0";
          address = "192.168.20.36/24";
        };
      };
      dnsmasq = {
        rangeStart = "200";
        port = "53";
        server = [ ];
      };
    };
    "fake-isp" = {
      system = "x86_64-linux";
      user = "misuzu";
      hostname = "fake-isp";
      networks = {
        wan = {
          IF = "enp5s0";
          address = "10.150.150.5/24";
        };
        br = {
          IF = "enp6s0";
          address = "fd42:3a98:dc40:52c6::254/64";
        };
      };
    };
  };
}
