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
  systemd.services.systemd-networkd.environment = {
    Environment = "SYSTEMD_LOG_LEVEL=debug";
  };
  systemd.network = {
    config.networkConfig = {
      #NOTE: https://scottstuff.net/posts/2025/02/25/frr-vs-systemd-networkd/
      ManageForeignNextHops = false;
      ManageForeignRoutes = false;
      ManageForeignRoutingPolicyRules = false;
    };
    netdevs =
      let
        inherit (lib) listToAttrs nameValuePair range;
        macvlans = listToAttrs (
          map (
            x:
            nameValuePair "macvlan${x}" {
              netdevConfig = {
                Name = "macvlan${x}";
                Kind = "macvlan";
              };
              macvlanConfig = {
                Mode = "vepa";
              };
            }
          ) (range 0 4)
        );
      in
      {
        "5-lo0" = {
          netdevConfig = {
            Name = "lo0";
            Kind = "dummy";
            MTUBytes = 65536;
          };
        };
        "5-enp7s0.${switch_id}" = {
          netdevConfig = {
            Name = "enp7s0.${switch_id}";
            Kind = "vlan";
          };
          vlanConfig = {
            Id = lib.toInt switch_id;
          };
        };
        "5-lo10001" = {
          netdevConfig = {
            Name = "lo10001";
            Kind = "dummy";
            Description = "Loopback interface for tennent 1";
          };
        };
        "5-vrf10001" = {
          netdevConfig = {
            Name = "vrf10001";
            Kind = "vrf";
            Description = "L3 VNI for tennent 1";
          };
          vrfConfig = {
            Table = 10001;
          };
        };
        "5-br10001" = {
          netdevConfig = {
            Name = "br10001";
            Kind = "bridge";
            Description = "Bridge for tennent 1";
          };
          bridgeConfig = {
            ForwardDelaySec = 0;
            STP = false;
          };
        };
        "5-vni10001" = {
          netdevConfig = {
            Name = "vni10001";
            Kind = "vxlan";
            Description = "VXLAN interface for tennent 1";
          };
          vxlanConfig = {
            VNI = 10001;
            DestinationPort = 4789;
            MacLearning = false;
            ReduceARPProxy = true;
            Independent = true;
            Local = "10.1.254.${switch_id}";
          };
        };
        "5-lo10002" = {
          netdevConfig = {
            Name = "lo10002";
            Kind = "dummy";
            Description = "Loopback interface for tennent 2";
          };
        };
        "5-vrf10002" = {
          netdevConfig = {
            Name = "vrf10002";
            Kind = "vrf";
            Description = "L3 VNI for tennent 1";
          };
          vrfConfig = {
            Table = 10002;
          };
        };
        "5-br10002" = {
          netdevConfig = {
            Name = "br10002";
            Kind = "bridge";
            Description = "Bridge for tennent 2";
          };
          bridgeConfig = {
            ForwardDelaySec = 0;
            STP = false;
          };
        };
        "5-vni10002" = {
          netdevConfig = {
            Name = "vni10002";
            Kind = "vxlan";
            Description = "VXLAN interface for tennent 2";
          };
          vxlanConfig = {
            DestinationPort = 4789;
            VNI = 10002;
            MacLearning = false;
            ReduceARPProxy = true;
            Independent = true;
            Local = "10.1.254.${switch_id}";
          };
        };
      };
    networks = {
      "6-lo0" = {
        name = "lo0";
        address = [
          "10.1.254.${switch_id}/32"
        ];
      };
      "7-enp7s0" = {
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
        address = [
          "192.168.12${switch_id}.2/30"
        ];
      };
      "10-enp7s0.${switch_id}" = {
        name = "enp7s0.${switch_id}";
        address = [
          "192.168.13${switch_id}.2/30"
        ];
      };
      "20-vrf10001" = {
        name = "vrf10001";
        address = [ "127.0.0.1/8" ];
      };
      "20-lo10001" = {
        name = "lo10001";
        vrf = [ "vrf10001" ];
        address = [
          "172.16.10.${switch_id}/32"
        ];
      };
      "21-br10001" = {
        name = "br10001";
        vrf = [ "vrf10001" ];
      };
      "22-vni10001" = {
        name = "vni10001";
        bridge = [ "br10001" ]; # connect vni10001 to br0
        bridgeConfig = {
          NeighborSuppression = false;
          Learning = false;
        };
      };
      "20-vrf10002" = {
        name = "vrf10002";
        address = [ "127.0.0.1/8" ];
      };
      "20-lo10002" = {
        name = "lo10002";
        vrf = [ "vrf10002" ];
        address = [
          "172.16.10.${switch_id}/32"
        ];
      };
      "21-br10002" = {
        name = "br10002";
        vrf = [ "vrf10002" ];
      };
      "22-vni10002" = {
        name = "vni10002";
        bridge = [ "br10002" ]; # connect vni10002 to br0
        bridgeConfig = {
          NeighborSuppression = false;
          Learning = false;
        };
      };
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
  #         bridge = "${pkgs.iproute2}/bin/bridge";
  #         vid_vni_pairs = {
  #           "10" = "100010"; # L2VNI
  #           "20" = "100020"; # L2VNI
  #           "30" = "10030"; # L2VNI
  #           "40" = "100010"; # L2VNI
  #           "50" = "100010"; # L2VNI
  #         };
  #         script_per_pair = vid: vni: ''
  #           ${bridge} vlan add dev vxlan0 vid ${vid}
  #           ${bridge} vni add dev vxlan0 vni ${vni}
  #           ${bridge} vlan add dev vxlan0 vid ${vid} tunnel_info id ${vni}
  #         '';
  #       in
  #       ''
  #         ${concatStringsSep "\n" (mapAttrsToList script_per_pair vid_vni_pairs)}
  #       '';
  #   };
  # };
}
