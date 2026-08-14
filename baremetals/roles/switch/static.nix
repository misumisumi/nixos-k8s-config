{
  switch = {
    kaho = {
      uuid = "66371d82-b417-481c-b85c-8ee9a8e6f304";
      system = "x86_64-linux";
      user = "renako";
      hostname = "kaho";

      networks = {
        wan = {
          IF = "enp4s0f0";
        };
        manage = {
          IF = "eno1";
          address = "192.168.2.42/24";
        };
        intra10G = {
          IF = "enp4s0f1";
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
          address = "192.168.2.41/24";
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
      BR = "2404:9200:225:100::64";
      CE = "240b:13:1a65:a100:e:91a:6500:a100";
      IPIP6_IPv4 = "14.9.26.101";
      PSID = 161;
    };
  };
}
