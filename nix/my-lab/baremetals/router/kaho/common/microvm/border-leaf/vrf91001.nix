{
  systemd.network = {
    netdevs = {
      br91001 = {
        netdevConfig = {
          Name = "br91001";
          Kind = "bridge";
          Description = "Bridge for VNI 91001";
        };
      };
      vxlan91001 = {
        netdevConfig = {
          Name = "vxlan91001";
          Kind = "vxlan";
          Description = "VXLAN VNI 91001";
        };
        vxlanConfig = {
          VNI = 91001;
          DestinationPort = 4791;
          MacLearning = false;
          ReduceARPProxy = true;
          Independent = true;
        };
      };
      vrf91001 = {
        netdevConfig = {
          Name = "vrf91001";
          Kind = "vrf";
          Description = "WAN";
        };
        vrfConfig = {
          Table = 91001;
        };
      };
      lo91001 = {
        netdevConfig = {
          Name = "lo91001";
          Kind = "dummy";
        };
      };
    };
    networks = {
      "10-enp0s5" = {
        name = "enp0s5";
        vrf = [ "vrf91001" ];
        networkConfig = {
          Description = "WAN Interface";
        };
      };
      "10-lo91001" = {
        name = "lo91001";
        vrf = [ "vrf91001" ];
        address = [
          "10.1.254.253/32"
        ];
      };
      "20-vrf91001" = {
        name = "vrf91001";
      };
      "20-br91001" = {
        name = "br91001";
        vrf = [ "vrf91001" ];
      };
      "21-vxlan91001" = {
        name = "vxlan91001";
        bridge = [ "br91001" ];
        bridgeConfig = {
          NeighborSuppression = false;
          Learning = false;
        };
      };
    };
  };
}
