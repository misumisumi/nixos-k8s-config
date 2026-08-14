{
  mngr = {
    naokosan = {
      system = "x86_64-linux";
      user = "misuzu";
      hostname = "naokosan";
      networks = {
        manage = {
          IF = "enp5s0";
          address = "192.168.2.30/24";
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
          address = "192.168.2.36/24";
        };
      };
      dnsmasq = {
        rangeStart = "";
        port = "53";
        server = [ ];
      };
    };
  };
}
