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
    # netdevs = {
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
    #   br0 = {
    #     netdevConfig = {
    #       Name = "br0";
    #       Kind = "brswitch_idge";
    #       MACAddress = "11:22:33:44:55:66";
    #     };
    #     brswitch_idgeConfig = {
    #       DefaultPVswitch_id = "none";
    #       VLANFiltering = true;
    #     };
    #   };
    #   vxlan0 = {
    #     netdevConfig = {
    #       Name = "vxlan0";
    #       Kind = "vxlan";
    #       MACAddress = "11:22:33:44:55:66";
    #     };
    #     vxlanConfig = {
    #       DestinationPort = 4789;
    #       MacLearning = true;
    #       ReduceARPProxy = true;
    #     };
    #     extraConfig = ''
    #       [VXLAN]
    #       External=yes
    #       VNIFilter=yes
    #     '';
    #   };
    #   vrf1 = {
    #     netdevConfig = {
    #       Name = "vrf1";
    #       Kind = "vrf";
    #     };
    #     vrfConfig = {
    #       Table = 1100;
    #     };
    #   };
    #   "br0.vrf1" = {
    #     netdevConfig = {
    #       Name = "br0.vrf1";
    #       Kind = "vlan";
    #       MACAddress = "11:22:33:44:55:66";
    #     };
    #   };
    #   vrf2 = {
    #     netdevConfig = {
    #       Name = "vrf2";
    #       Kind = "vrf";
    #     };
    #     vrfConfig = {
    #       Table = 1200;
    #     };
    #   };
    #   "br0.vrf2" = {
    #     netdevConfig = {
    #       Name = "br0.vrf2";
    #       Kind = "vlan";
    #       MACAddress = "11:22:33:44:55:66";
    #     };
    #   };
    #   vrf3 = {
    #     netdevConfig = {
    #       Name = "vrf3";
    #       Kind = "vrf";
    #     };
    #     vrfConfig = {
    #       Table = 1300;
    #     };
    #   };
    #   vlan10 = {
    #     netdevConfig = {
    #       Name = "vlan10";
    #       Kind = "vlan";
    #       MACAddress = "aa:bb:cc:10:00:0${switch_id}";
    #     };
    #   };
    #   vlan20 = {
    #     netdevConfig = {
    #       Name = "vlan20";
    #       Kind = "vlan";
    #       MACAddress = "aa:bb:cc:20:00:0${switch_id}";
    #     };
    #   };
    #   vlan30 = {
    #     netdevConfig = {
    #       Name = "vlan30";
    #       Kind = "vlan";
    #       MACAddress = "aa:bb:cc:30:00:0${switch_id}";
    #     };
    #   };
    #   vlan40 = {
    #     netdevConfig = {
    #       Name = "vlan40";
    #       Kind = "vlan";
    #       MACAddress = "aa:bb:cc:40:00:0${switch_id}";
    #     };
    #   };
    #   vlan50 = {
    #     netdevConfig = {
    #       Name = "vlan50";
    #       Kind = "vlan";
    #       MACAddress = "aa:bb:cc:50:00:0${switch_id}";
    #     };
    #   };
    # };
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
        address = [
          "192.168.11${switch_id}.2/30"
        ];
      };
      "10-enp6s0" = {
        name = "enp6s0";
      };
      "10-enp7s0.${switch_id}" = {
        name = "enp7s0.${switch_id}";
        address = [
          "192.168.21${switch_id}.2/30"
        ];
      };
      # "20-br0" = {
      #   name = "br0";
      #   vlan = [
      #     "br0.vrf1"
      #     "br0.vrf2"
      #   ];
      #   networkConfig = {
      #     LinkLocalAddressing = false;
      #   };
      #   brswitch_idgeVLANs = [
      #     {
      #       VLAN = 10;
      #     }
      #     {
      #       VLAN = 20;
      #     }
      #     {
      #       VLAN = 30;
      #     }
      #     {
      #       VLAN = 1100;
      #     }
      #     {
      #       VLAN = 1200;
      #     }
      #     {
      #       VLAN = 1300;
      #     }
      #   ];
      # };
      # "20-vxlan0" = {
      #   name = "vxlan0";
      #   brswitch_idge = [ "br0" ];
      #   networkConfig = {
      #     LinkLocalAddressing = false;
      #   };
      #   # brswitch_idgeConfig = {
      #   #   VLANTunnel = true;
      #   # };
      # };
      # "30-br0.vrf1" = {
      #   name = "br0.vrf1";
      #   vrf = [ "vrf1" ];
      #   networkConfig = {
      #     LinkLocalAddressing = false;
      #   };
      # };
      # "30-br0.vrf2" = {
      #   name = "br0.vrf2";
      #   vrf = [ "vrf2" ];
      #   networkConfig = {
      #     LinkLocalAddressing = false;
      #   };
      # };
      # "40-vlan10" = {
      #   name = "vlan10";
      #   vrf = [ "vrf1" ];
      #   address = [
      #     "10.0.10.1/24"
      #     "2001:db8:0:10::1/64"
      #   ];
      # };
      # "40-vlan20" = {
      #   name = "vlan20";
      #   vrf = [ "vrf2" ];
      #   address = [
      #     "10.0.20.1/24"
      #     "2001:db8:0:20::1/64"
      #   ];
      # };
      # "40-vlan30" = {
      #   name = "vlan30";
      #   vrf = [ "vrf3" ];
      #   address = [
      #     "10.0.30.1/24"
      #     "2001:db8:0:30::1/64"
      #   ];
      # };
      # "40-vlan40" = {
      #   name = "vlan40";
      #   address = [
      #     "10.0.40.1/24"
      #     "2001:db8:0:40::1/64"
      #   ];
      # };
      # "40-vlan50" = {
      #   name = "vlan50";
      #   address = [
      #     "10.0.50.1/24"
      #     "2001:db8:0:50::1/64"
      #   ];
      #   networkConfig = {
      #     IPv4Forwarding = false;
      #     IPv6Forwarding = false;
      #   };
      # };
      # "20-vlan10agw" = {
      #   name = "vlan10agw";
      #   address = [
      #     "10.0.10.1/24"
      #     "2001:db:0:10::/64"
      #   ];
      # };
    };
  };
  # systemd.services = {
  #   "tunneling-vxlan" = {
  #     description = "Set up VXLAN tunneling";
  #     after = [ "network.target" ];
  #     wantedBy = [ "multi-user.target" ];
  #     serviceConfig = {
  #       Type = "oneshot";
  #       RemainAfterExit = true;
  #     };
  #     script =
  #       let
  #         inherit (lib) concatStringsSep mapAttrsToList;
  #         brswitch_idge = "${pkgs.iproute2}/bin/brswitch_idge";
  #         vswitch_id_vni_pairs = {
  #           "1100" = "100"; # L3VNI
  #           "1200" = "200"; # L3VNI
  #           "10" = "110"; # L2VNI
  #           "20" = "220"; # L2VNI
  #           "30" = "330"; # L2VNI
  #           "40" = "440"; # L2VNI
  #           "50" = "550"; # L2VNI
  #         };
  #         script_per_pair = vswitch_id: vni: ''
  #           ${brswitch_idge} vlan add dev vxlan0 vswitch_id ${vswitch_id}
  #           ${brswitch_idge} vlan add dev vxlan0 vni ${vni}
  #           ${brswitch_idge} vlan add dev vxlan vswitch_id ${vswitch_id} tunnel_info switch_id ${vni}
  #         '';
  #       in
  #       ''
  #         ${brswitch_idge} link set dev vxlan vlan_tunnel on
  #         ${concatStringsSep "\n" (mapAttrsToList script_per_pair vswitch_id_vni_pairs)}
  #       '';
  #   };
  # };
}
