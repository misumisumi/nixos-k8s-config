{
  switch = {
    kaho = {
      uuid = "501b2357-38e9-43ad-a841-1b620418c959";
      system = "x86_64-linux";
      user = "renako";
      hostname = "kaho";

      networks = {
        manage = {
          IF = "enp6s0";
          address = "192.168.20.42/24";
          mtu = 1500;
        };
        intra40G_1 = {
          IF = "enp8s0";
          mtu = 9000;
        };
        intra40G_2 = {
          IF = "enp9s0";
          mtu = 9000;
        };
        intra40G_3 = {
          IF = "enp10s0";
          mtu = 9000;
        };
        intra40G_4 = {
          IF = "enp11s0";
          mtu = 9000;
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
          mtu = 1500;
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
    # kaho の microvm.vms としてビルドされるため単体の nixosConfiguration は生成しない
    borderLeaf = {
      notShow = true;
      system = "x86_64-linux";
      user = "renako";
      hostname = "borderLeaf";
      networks = { };
      mtu = 9000;
      bgp = {
        routerId = "10.10.10.253";
        AS = "65020";
      };
    };
    borderRouter = {
      notShow = true;
      system = "x86_64-linux";
      user = "renako";
      hostname = "borderRouter";
      networks = {
        host = {
          IF = "enp0s5";
        };
        wan = {
          IF = "enp0s4";
          # macvtap の親 (ホスト側) IF
          parent = "enp5s0";
          mtu = 1500;
        };
      };
      mtu = 9000;
      bgp = {
        routerId = "10.10.10.254";
        AS = "64512";
        # wan VRF の routing table 番号 (EVPN では使わない)。
        wanVrfTable = 30001;
      };
      BR = "fd42:3a98:dc40:52c6::254";
      CE = "fd42:3a98:dc40:52c6::100";
      IPIP6_IPv4 = "203.0.113.1";
      PSID = 0;
    };
    homeLeaf = {
      notShow = true;
      system = "x86_64-linux";
      user = "renako";
      hostname = "homeLeaf";
      networks = {
        host = {
          IF = "enp0s3";
        };
        apTrunk = {
          IF = "enp0s4";
          # macvtap の親 (ホスト側) IF
          parent = "enp7s0";
        };
        intra10G_2 = {
          IF = "enp0s5";
          parent = "enp12s0";
        };
        intra40G_4 = {
          IF = "enp0s6";
          parent = "enp11s0";
        };
      };
      mtu = 9000;
      bgp = {
        routerId = "10.10.10.250";
        AS = "65030";
      };
    };
    svcLeaf = {
      notShow = true;
      system = "x86_64-linux";
      user = "renako";
      hostname = "svcLeaf";
      networks = {
        host = {
          IF = "enp0s3";
        };
      };
      mtu = 9000;
      bgp = {
        routerId = "10.10.10.240";
        AS = "65040";
      };
    };
  };
}
