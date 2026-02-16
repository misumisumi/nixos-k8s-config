{
  systemd.network = {
    netdevs = {
      lo91001 = {
        netdevConfig = {
          Name = "lo91001";
          Kind = "dummy";
        };
      };
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
          # MACAddress = "${vxlan_macaddr}";
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
    };
    networks = {
      "10-enp0s5" = {
        name = "enp0s5";
        address = [ "192.168.255.2/30" ];
        vrf = [ "vrf91001" ];
      };
      # "20-lo91001" = {
      #   vrf = [ "vrf91001" ];
      #   name = "lo91001";
      #   address = [
      #     "10.254.254.2/32"
      #   ];
      # };
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
