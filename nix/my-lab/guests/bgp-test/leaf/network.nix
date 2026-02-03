{
  lib,
  pkgs,
  hostname,
  switch_id,
  ...
}:
{
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.default.rp_filter" = 0;
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv6.conf.default.forwarding" = 1;
  };
  networking = {
    hostName = hostname;
    useNetworkd = true;
    useDHCP = false;
    firewall.enable = false;
  };
  systemd.network = {
    config.networkConfig = {
      #NOTE: https://scottstuff.net/posts/2025/02/25/frr-vs-systemd-networkd/
      ManageForeignNextHops = false;
      ManageForeignRoutes = false;
      ManageForeignRoutingPolicyRules = false;
    };
    netdevs = {
      lo0 = {
        netdevConfig = {
          Name = "lo0";
          Kind = "dummy";
          MTUBytes = 65536;
        };
      };
      "enp7s0.${switch_id}" = {
        netdevConfig = {
          Name = "enp7s0.${switch_id}";
          Kind = "vlan";
        };
        vlanConfig = {
          Id = lib.toInt switch_id;
        };
      };
    };
    netdevs = {
      #   vlan10agw = {
      #     netdevConfig = {
      #       Name = "vlan10agw";
      #       Kind = "macvlan";
      #       MACAddress = "02:00:00:00:10:01";
      #     };
      #     macvlanConfig = {
      #       Mode = "private";
      #     };
      #   };
      br0 = {
        netdevConfig = {
          Name = "br0";
          Kind = "bridge";
          MACAddress = "11:22:33:44:55:66";
        };
        bridgeConfig = {
          DefaultPVswitch_id = "none";
          VLANFiltering = true;
        };
      };
      vxlan0 = {
        netdevConfig = {
          Name = "vxlan0";
          Kind = "vxlan";
          MACAddress = "11:22:33:44:55:66";
        };
        vxlanConfig = {
          DestinationPort = 4789;
          MacLearning = true;
          ReduceARPProxy = true;
        };
        extraConfig = ''
          [VXLAN]
          VNI=10000
          VNI=20000
          VNI=11000
          VNI=22000
        '';
      };
      vrf10000 = {
        netdevConfig = {
          Name = "vrf10000";
          Kind = "vrf";
        };
        vrfConfig = {
          Table = 10000;
        };
      };
      vrf20000 = {
        netdevConfig = {
          Name = "vrf20000";
          Kind = "vrf";
        };
        vrfConfig = {
          Table = 20000;
        };
      };
      vrf30000 = {
        netdevConfig = {
          Name = "vrf30000";
          Kind = "vrf";
        };
        vrfConfig = {
          Table = 30000;
        };
      };
      vrf10000br0 = {
        netdevConfig = {
          Name = "vrf10000br0";
          Kind = "vlan";
          MACAddress = "11:22:33:44:55:66";
        };
      };
      vrf20000br0 = {
        netdevConfig = {
          Name = "vrf20000br0";
          Kind = "vlan";
          MACAddress = "11:22:33:44:55:66";
        };
      };
      vlan10 = {
        netdevConfig = {
          Name = "vlan10";
          Kind = "vlan";
          MacAddress = "aa:bb:cc:00:00:6e";
        };
      };
      vlan20 = {
        netdevConfig = {
          Name = "vlan20";
          Kind = "vlan";
          MacAddress = "aa:bb:cc:00:00:dc";
        };
      };
      vlan30 = {
        netdevConfig = {
          Name = "vlan30";
          Kind = "vlan";
          MacAddress = "aa:bb:cc:00:01:4a";
        };
      };
    };
    networks = {
      "5-lo0" = {
        name = "lo0";
        address = [
          "10.0.254.${switch_id}/32"
        ];
      };
      "6-enp7s0" = {
        name = "enp7s0";
        vlan = [ "enp7s0.${switch_id}" ];
      };
      "10-enp5s0" = {
        name = "enp5s0";
        bridge = [ "br0" ];
        address = [
          "192.168.11${switch_id}.2/30"
        ];
      };
      "10-enp6s0" = {
        name = "enp6s0";
        bridge = [ "br0" ];
      };
      "10-enp7s0.${switch_id}" = {
        name = "enp7s0.${switch_id}";
        bridge = [ "br0" ];
        address = [
          "192.168.21${switch_id}.2/30"
        ];
      };
      "20-br0" = {
        name = "br0";
        vlan = [
          "vlan10"
          "vlan20"
        ];
        networkConfig = {
          LinkLocalAddressing = false;
        };
        bridgeVLANs = [
          {
            VLAN = 10;
          }
          {
            VLAN = 20;
          }
          {
            VLAN = 30;
          }
          {
            VLAN = 10000;
          }
          {
            VLAN = 20000;
          }
          {
            VLAN = 30000;
          }
        ];
      };
      "20-vxlan0" = {
        name = "vxlan0";
        bridge = [ "br0" ]; # connect vxlan0 to br0
        networkConfig = {
          LinkLocalAddressing = false;
        };
        bridgeConfig = {
          VLANTunnel = true;
        };
        bridgeVLANs = [
          {
            VLAN = 10;
          }
          {
            VLAN = 20;
          }
          {
            VLAN = 30;
          }
          {
            VLAN = 10000;
          }
          {
            VLAN = 20000;
          }
          {
            VLAN = 30000;
          }
        ];
      };
      "30-vrf10000br0" = {
        name = "vrf10000br0";
        vrf = [ "vrf10000" ];
        networkConfig = {
          LinkLocalAddressing = false;
        };
      };
      "30-vrf20000br0" = {
        name = "vrf20000br0";
        vrf = [ "vrf20000" ];
        networkConfig = {
          LinkLocalAddressing = false;
        };
      };
      "40-vlan10" = {
        name = "vlan10";
        vrf = [ "vrf10000" ];
        address = [
          "172.16.10.1/24"
        ];
      };
      "40-vlan20" = {
        name = "vlan20";
        vrf = [ "vrf20000" ];
        address = [
          "172.16.20.1/24"
        ];
      };
      "40-vlan30" = {
        name = "vlan30";
        vrf = [ "vrf30000" ];
        address = [
          "172.16.30.1/24"
        ];
      };
    };
  };
  systemd.services = {
    "tunneling-vxlan" = {
      description = "Set up VXLAN tunneling";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script =
        let
          inherit (lib) concatStringsSep mapAttrsToList;
          bridge = "${pkgs.iproute2}/bin/bridge";
          vid_vni_pairs = {
            "10000" = "10000"; # L3VNI
            "20000" = "20000"; # L3VNI
            "10" = "11000"; # L2VNI
            "20" = "22000"; # L2VNI
            "30" = "33000"; # L2VNI
            "40" = "44000"; # L2VNI
            "50" = "55000"; # L2VNI
          };
          script_per_pair = vswitch_id: vni: ''
            ${bridge} vlan add dev vxlan v ${vswitch_id} tunnel_info id ${vni}
          '';
        in
        ''
          ${concatStringsSep "\n" (mapAttrsToList script_per_pair vid_vni_pairs)}
        '';
    };
  };
}
