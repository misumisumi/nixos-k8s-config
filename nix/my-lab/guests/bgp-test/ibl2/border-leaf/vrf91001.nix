let
  vxlan1_macaddr = "b2:4b:95:b6:b5:b3";
  vlan_macaddr = tennant: vid: "aa:bb:cc:ee:0${toString tennant}:${toString vid}";
in
{
  systemd.network = {
    netdevs = {
      br1 = {
        netdevConfig = {
          Name = "br1";
          Kind = "bridge";
          Description = "Sigle VLAN Aware Bridge";
          MACAddress = "${vxlan1_macaddr}";
        };
        bridgeConfig = {
          DefaultPVID = 1;
          VLANFiltering = true;
        };
      };
      vxlan1 = {
        netdevConfig = {
          Name = "vxlan1";
          Kind = "vxlan";
          Description = "Sigle VXLAN Aware Interface";
          MACAddress = "${vxlan1_macaddr}";
        };
        vxlanConfig = {
          DestinationPort = 4790;
          MacLearning = false;
          ReduceARPProxy = true;
          Independent = true;
          Local = "10.1.254.254";
        };
        extraConfig = ''
          [VXLAN]
          VNIFilter=yes
          External=yes
        '';
      };
      vrf91001 = {
        netdevConfig = {
          Name = "vrf91001";
          Kind = "vrf";
          Description = "tennent 1";
        };
        vrfConfig = {
          Table = 91001;
        };
      };
      vni91001 = {
        netdevConfig = {
          Name = "vni91001";
          Kind = "vlan";
          Description = "VLAN 10 for tennent 1";
          MACAddress = "${vxlan1_macaddr}";
        };
        vlanConfig = {
          Id = 1001;
        };
      };
      tnx-vlan1 = {
        netdevConfig = {
          Name = "tnx-vlan1";
          Kind = "vlan";
          Description = "VLAN 1 for tennent X";
        };
        vlanConfig = {
          Id = 1;
        };
      };
      tnx-vlan1agw = {
        netdevConfig = {
          Name = "tn1-vlan10agw";
          Kind = "macvlan";
          Description = "Anycast Gateway VLAN 1 for tennent X";
          MACAddress = "${vlan_macaddr 1 "01"}";
        };
        macvlanConfig = {
          Mode = "private";
        };
      };
    };
    networks = {
      "20-vrf91001" = {
        name = "vrf91001";
      };
      "20-br1" = {
        name = "br1";
        networkConfig = {
          IPv6LinkLocalAddressGenerationMode = "none";
        };
        vlan = [
          "vni91001"
        ];
        bridgeVLANs = [
          {
            VLAN = 1001;
          }
        ];
        bridgeFDBs = [
          {
            MACAddress = "${vlan_macaddr 1 "01"}";
          }
        ];
      };
      "21-vxlan1" = {
        name = "vxlan1";
        bridge = [ "br1" ];
        networkConfig = {
          IPv6LinkLocalAddressGenerationMode = "none";
        };
        bridgeConfig = {
          NeighborSuppression = false;
          Learning = false;
        };
        extraConfig = ''
          [Bridge]
          VLANTunnel=yes
        '';
      };
      "21-vni91001" = {
        name = "vni91001";
        vrf = [ "vrf91001" ];
        networkConfig = {
          IPv6LinkLocalAddressGenerationMode = "none";
        };
      };
      "30-tn1-vlan10" = {
        name = "tn1-vlan10";
        vrf = [ "vrf91001" ];
        macvlan = [ "tn1-vlan1agw" ];
        address = [ "172.16.10.100/24" ];
      };
      "30-tn1-vlan10agw" = {
        name = "tn1-vlan1agw";
        vrf = [ "vrf91001" ];
        address = [ "172.16.10.1/24" ];
      };
    };
  };
}
