{
  compute = {
    virtualIPs = {
      notShow = true;
      linstor = {
        address = "10.10.10.100";
        cidr = "32";
      };
      nfs = {
        address = "10.10.10.101";
        cidr = "32";
      };
      incus = {
        address = "192.168.2.102";
        cidr = "24";
      };
    };
    ajisai = {
      uuid = "e6ae54f8-c9b9-4bc0-a3a2-70818ed1a0d2";
      system = "x86_64-linux";
      user = "renako";
      hostname = "ajisai";
      networks = {
        manage = {
          IF = "enp5s0";
          address = "192.168.2.50/24";
        };
        intra10G = {
          IF = "enp6s0";
        };
        intra40G = {
          IF = "enp7s0";
        };
      };
      bgp = {
        routerId = "10.10.10.50";
        AS = "65050";
      };
    };
    mai = {
      uuid = "27161944-492d-4225-ae42-73a43467e797";
      system = "x86_64-linux";
      user = "renako";
      hostname = "mai";
      networks = {
        manage = {
          IF = "enp5s0";
          address = "192.168.2.51/24";
        };
        intra10G = {
          IF = "enp6s0";
        };
        intra40G = {
          IF = "enp7s0";
        };
      };
      bgp = {
        routerId = "10.10.10.51";
        AS = "65051";
      };
    };
    satsuki = {
      uuid = "ef44a86f-544b-4e81-8fa3-0e7bbe8609b6";
      system = "x86_64-linux";
      user = "renako";
      hostname = "satsuki";
      networks = {
        manage = {
          IF = "enp5s0";
          address = "192.168.2.52/24";
        };
        intra10G = {
          IF = "enp6s0";
        };
        intra40G = {
          IF = "enp7s0";
        };
      };
      bgp = {
        routerId = "10.10.10.52";
        AS = "65052";
      };
    };
  };
}
