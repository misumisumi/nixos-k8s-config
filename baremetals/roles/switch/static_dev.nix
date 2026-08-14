{
  switch = {
    kaho = {
      uuid = "501b2357-38e9-43ad-a841-1b620418c959";
      system = "x86_64-linux";
      user = "renako";
      hostname = "kaho";

      networks = {
        wan = {
          IF = "enp5s0";
        };
        manage = {
          IF = "enp6s0";
          address = "192.168.20.42/24";
        };
        intra10G = {
          IF = "enp7s0";
        };
        intra40G_1 = {
          IF = "enp8s0";
        };
        intra40G_2 = {
          IF = "enp9s0";
        };
        intra40G_3 = {
          IF = "enp10s0";
        };
        intra40G_4 = {
          IF = "enp11s0";
        };
      };

      bgp = {
        routerId = "10.10.10.42";
        AS = "65012";
        l2vpnListenRange = "10.10.10.0/24";
      };
    };
    sks8300-8x = {
      notImage = true;
      system = "x86_64-linux";
      user = "renako";
      hostname = "sks8300-8x";

      networks = {
        manage = {
          IF = "eth0";
          address = "192.168.20.41/24";
        };
      };
      bgp = {
        AS = "65011";
        routerId = "10.10.10.41";
        l2vpnListenRange = "10.10.10.0/24";
      };
    };
  };
  microvm = {
    borderLeaf = {
      system = "x86_64-linux";
      user = "renako";
      hostname = "borderLeaf";
      networks = { };
      bgp = {
        routerId = "10.10.10.253";
        AS = "65020";
      };
    };
    borderRouter = {
      system = "x86_64-linux";
      user = "renako";
      hostname = "borderRouter";
      networks = { };
      bgp = {
        routerId = "10.10.10.254";
        AS = "64512";
      };
      BR = "fd42:3a98:dc40:52c6::254";
      CE = "fd42:3a98:dc40:52c6::100";
      IPIP6_IPv4 = "203.0.113.1";
      PSID = 0;
    };
  };
}
