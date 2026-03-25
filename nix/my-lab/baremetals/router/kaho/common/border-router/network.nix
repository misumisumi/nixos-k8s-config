{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    listToAttrs
    nameValuePair
    range
    toInt
    ;
in
{
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.default.rp_filter" = 0;
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv6.conf.default.forwarding" = 1;
  };
  networking = {
    hostName = "router";
    useNetworkd = true;
    useDHCP = false;
    # firewall.enable = true;
    nftables = {
      enable = true;
      tables = {
        "nat" = {
          enable = true;
          family = "inet";
          content = ''
            chain postrouting {
              type nat hook postrouting priority 100; policy accept;
              oifname "enp0s4" masquerade
            }
          '';
        };
      };
    };
  };

  systemd.network =
    let
      networkConf4WAN = {
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
              # MACAddress = "${vxlan_macaddr}";
            };
            vxlanConfig = {
              VNI = 91001;
              DestinationPort = 4789;
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
    in
    {
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
          };
        };
      } # ;
      // networkConf4WAN.netdevs;
      networks = {
        "5-lo0" = {
          name = "lo0";
          address = [
            "10.1.254.254/32"
          ];
        };
        "10-enp0s3" = {
          name = "enp0s3";
          networkConfig = {
            Description = "Point to Point link";
          };
        };
        "10-enp0s4" = {
          name = "enp0s4";
          # vrf = [ "vrf91001" ];
          address = [ "10.150.150.10/24" ];
          gateway = [ "10.150.150.1" ];
          dns = [
            "1.1.1.1"
            "8.8.8.8"
          ];
          networkConfig = {
            Description = "WAN Interface";
          };
        };
      } # ;
      // networkConf4WAN.networks;

    };
}
