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
    hostName = "border-leaf";
    useNetworkd = true;
    useDHCP = false;
    firewall.enable = false;
  };

  systemd.network =
    let
      networkConf4LAN =
        let
          vxlan0_macaddr = "b2:4b:95:b6:a4:a9";
          vlan_macaddr = tennant: vid: "aa:bb:cc:ee:0${toString tennant}:${toString vid}";
        in
        {
          netdevs = {
            br0 = {
              netdevConfig = {
                Name = "br0";
                Kind = "bridge";
                Description = "Sigle VLAN Aware Bridge";
                MACAddress = "${vxlan0_macaddr}";
              };
              bridgeConfig = {
                # DefaultPVID = "none";
                DefaultPVID = 1;
                VLANFiltering = true;
              };
            };
            vxlan0 = {
              netdevConfig = {
                Name = "vxlan0";
                Kind = "vxlan";
                Description = "Sigle VXLAN Aware Interface";
                MACAddress = "${vxlan0_macaddr}";
              };
              vxlanConfig = {
                DestinationPort = 4789;
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
            vrf10001 = {
              netdevConfig = {
                Name = "vrf10001";
                Kind = "vrf";
                Description = "tennent 1";
              };
              vrfConfig = {
                Table = 10001;
              };
            };
            vni10001 = {
              netdevConfig = {
                Name = "vni10001";
                Kind = "vlan";
                Description = "VLAN 10 for tennent 1";
                MACAddress = "${vxlan0_macaddr}";
              };
              vlanConfig = {
                Id = 1001;
              };
            };
            tn1-vlan10 = {
              netdevConfig = {
                Name = "tn1-vlan10";
                Kind = "vlan";
                Description = "VLAN 10 for tennent 1";
              };
              vlanConfig = {
                Id = 10;
              };
            };
            tn1-vlan10agw = {
              netdevConfig = {
                Name = "tn1-vlan10agw";
                Kind = "macvlan";
                Description = "Anycast Gateway VLAN 10 for tennent 1";
                MACAddress = "${vlan_macaddr 1 10}";
              };
              macvlanConfig = {
                Mode = "private";
              };
            };
          };
          networks = {
            "20-vrf10001" = {
              name = "vrf10001";
            };
            "20-br0" = {
              name = "br0";
              networkConfig = {
                IPv6LinkLocalAddressGenerationMode = "none";
              };
              vlan = [
                "vni10001"
                "tn1-vlan10"
              ];
              bridgeVLANs = [
                {
                  VLAN = 1001;
                }
                {
                  VLAN = 10;
                }
              ];
              bridgeFDBs = [
                {
                  MACAddress = "${vlan_macaddr 1 10}";
                }
              ];
            };
            "21-vxlan0" = {
              name = "vxlan0";
              bridge = [ "br0" ];
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
            "21-vni10001" = {
              name = "vni10001";
              vrf = [ "vrf10001" ];
              networkConfig = {
                IPv6LinkLocalAddressGenerationMode = "none";
              };
            };
            "30-tn1-vlan10" = {
              name = "tn1-vlan10";
              vrf = [ "vrf10001" ];
              macvlan = [ "tn1-vlan10agw" ];
              address = [ "172.16.10.100/24" ];
            };
            "30-tn1-vlan10agw" = {
              name = "tn1-vlan10agw";
              vrf = [ "vrf10001" ];
              address = [ "172.16.10.1/24" ];
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
      }
      // networkConf4LAN.netdevs;
      networks = {
        "5-lo0" = {
          name = "lo0";
          address = [
            "10.1.254.253/32"
          ];
        };
        "10-enp0s3" = {
          name = "enp0s3";
          # address = [ "192.168.137.2/30" ];
          networkConfig = {
            Description = "40G Interface";
          };
        };
        "10-enp0s4" = {
          name = "enp0s4";
          # address = [ "192.168.254.2/30" ];
          networkConfig = {
            Description = "10G Interface";
          };
        };
      }
      // networkConf4LAN.networks;
    };
  systemd.services.systemd-networkd =
    let
      inherit (lib) concatStringsSep mapAttrsToList;
      cmd = x: "${pkgs.iproute2}/bin/${x}";
      ip = cmd "ip";
      bridge = cmd "bridge";

      vni_vid_pairs = {
        "10011" = "10"; # L2VNI
      };
      script_per_pair = vni: vid: ''
        ${bridge} vlan add dev vxlan0 vid ${vid}
        ${bridge} vni add dev vxlan0 vni ${vni}
        ${bridge} vlan add dev vxlan0 vid ${vid} tunnel_info id ${vni}
      '';
    in
    {
      environment = {
        SYSTEMD_LOG_LEVEL = "debug";
      };
      postStart = ''
        echo "Configuring VXLAN VLAN tunneling ..."
        for i in $(seq 1 5); do
          STATE=$(${ip} link show vxlan0 | ${pkgs.coreutils}/bin/head -n1 | ${pkgs.gnused}/bin/sed -e "s/.* state \([A-Z]*\)\s.*/\1/g")
          if [ "''${STATE}" = "UNKNOWN" ]; then
            ${bridge} vlan add dev vxlan0 vid 1001
            ${bridge} vni add dev vxlan0 vni 10001
            ${bridge} vlan add dev vxlan0 vid 1001 tunnel_info id 10001

            ${concatStringsSep "\n" (mapAttrsToList script_per_pair vni_vid_pairs)}
            echo "Configured VNI VLAN tunneling."
            break
          else
            sleep 2
          fi
        done
      '';
    };
}
