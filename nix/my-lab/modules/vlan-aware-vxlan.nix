# Single VXLAN Device supporting Multiple VLAN Aware Bridges
{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    flatten
    listToAttrs
    mapAttrsToList
    mkOption
    nameValuePair
    optionalAttrs
    types
    ;
  cfg = config.networking.vxlan.tenants;
  configPerTenant = types.submodule (
    { config, ... }:
    {
      options = {
        name = mkOption {
          type = types.str;
          description = "Name of tenant VXLAN.";
        };
        vrf = mkOption {
          type = types.str;
          visible = false;
          readOnly = true;
        };
        L3VNI = mkOption {
          type = types.submodule {
            options = {
              hwAddr = mkOption {
                type = types.str;
                description = "MAC address for tenant VXLAN interfaces.";
              };
              vni = mkOption {
                type = types.int;
                description = "VXLAN Network Identifier (VNI).";
              };
              vlan = mkOption {
                type = types.int;
                description = "VLAN ID.";
              };
              local = mkOption {
                type = types.str;
                description = "Local IP address for tenant VXLAN interfaces.";
              };
              destinationPort = mkOption {
                type = types.int;
                default = 4789;
                description = "Destination port for tenant VXLAN interfaces.";
              };
              vniIF = mkOption {
                type = types.str;
                visible = false;
                readOnly = true;
              };
              brIF = mkOption {
                type = types.str;
                visible = false;
                readOnly = true;
              };
              vxlanIF = mkOption {
                type = types.str;
                visible = false;
                readOnly = true;
              };
            };
          };
          description = ''
            Configuration for Single VLAN Aware Bridge and its single VXLAN interface of tenant.
            This is used to determine the VNI and VLAN ID for the single VXLAN interfaces of tenant.
          '';
        };
        vniVlanPairs = mkOption {
          type = types.listOf (
            types.submodule {
              options = {
                vni = mkOption {
                  type = types.int;
                  description = "VXLAN Network Identifier (VNI).";
                };
                vlan = mkOption {
                  type = types.int;
                  description = "VLAN ID.";
                };
                address = mkOption {
                  type = types.str;
                  description = "IP address for VLAN interface.";
                };
                anycastGateway = mkOption {
                  type = types.submodule {
                    options = {
                      hwAddr = mkOption {
                        type = types.str;
                        description = "Generate MAC address for anycast gateway of each VLAN-VNI.";
                      };
                      address = mkOption {
                        type = types.str;
                        description = "Generate IP address for anycast gateway of each VLAN-VNI.";
                      };
                    };
                  };
                };
              };
            }

          );
          description = ''
            List of VNI and VLAN ID pairs of tenant
            VNI must be unique across the tenants.
            VLAN ID is not unique across the tenants.
          '';
        };
        vniVlanPairs' = mkOption {
          type = types.listOf (
            types.submodule {
              options = {
                vni = mkOption {
                  type = types.int;
                  description = "VXLAN Network Identifier (VNI).";
                };
                vlan = mkOption {
                  type = types.int;
                  description = "VLAN ID.";
                };
                address = mkOption {
                  type = types.str;
                  description = "IP address for VLAN interface.";
                };
                vlanIF = mkOption {
                  type = types.str;
                };
                anycastGateway = mkOption {
                  type = types.submodule {
                    options = {
                      hwAddr = mkOption {
                        type = types.str;
                        description = "Generate MAC address for anycast gateway of each VLAN-VNI.";
                      };
                      address = mkOption {
                        type = types.str;
                        description = "Generate IP address for anycast gateway of each VLAN-VNI.";
                      };
                      IF = mkOption {
                        type = types.str;
                      };
                    };
                  };
                };
              };
            }
          );
          visible = false;
          readOnly = true;
        };
      };
      config = {
        vrf = config.name + "-vrf${toString config.L3VNI.vni}";
        L3VNI = {
          vniIF = config.name + "-vni${toString config.L3VNI.vni}";
          brIF = config.name + "-br";
          vxlanIF = config.name + "-vxlan";
        };
        vniVlanPairs' = map (
          x:
          let
            IFName = config.name + "-vlan${toString x.vlan}";
          in
          {
            inherit (x) vni vlan address;
            vlanIF = IFName;
            anycastGateway = {
              inherit (x.anycastGateway) hwAddr address;
              IF = IFName + "agw";
            };
          }
        ) config.vniVlanPairs;
      };
    }
  );
in
{
  options = {
    networking.vxlan.tenants = mkOption {
      type = types.attrsOf configPerTenant;
      description = "Configuration for Single VXLAN Device supporting Multiple VLAN Aware Bridges.";
    };
  };
  config =
    let
      genNetdevs = mapAttrsToList (
        n: v:
        [
          (nameValuePair "${v.L3VNI.brIF}" {
            netdevConfig = {
              Name = "${v.L3VNI.brIF}";
              Kind = "bridge";
              Description = "Sigle VLAN Aware Bridge for ${v.name} tenant";
              MACAddress = v.L3VNI.hwAddr;
            };
            bridgeConfig = {
              DefaultPVID = "none";
              VLANFiltering = true;
            };
          })
          (nameValuePair "${v.L3VNI.vxlanIF}" {
            netdevConfig = {
              Name = "${v.L3VNI.vxlanIF}";
              Kind = "vxlan";
              Description = "Single VXLAN interface for ${v.name}";
              MACAddress = v.L3VNI.hwAddr;
            };
            vxlanConfig = {
              DestinationPort = v.L3VNI.destinationPort;
              MacLearning = false;
              ReduceARPProxy = true;
              Independent = true;
              Local = v.L3VNI.local;
            };
            extraConfig = ''
              [VXLAN]
              VNIFilter=yes
              External=yes
            '';
          })
          (nameValuePair "${v.vrf}" {
            netdevConfig = {
              Name = "${v.vrf}";
              Kind = "vrf";
              Description = "VRF for ${v.name} tenant";
            };
            vrfConfig = {
              Table = v.L3VNI.vni;
            };
          })
          (nameValuePair "${v.L3VNI.vniIF}" {
            netdevConfig = {
              Name = "${v.L3VNI.vniIF}";
              Kind = "vlan";
              Description = "VLAN ${toString v.L3VNI.vlan} for ${v.name} tenant";
              MACAddress = v.L3VNI.hwAddr;
            };
            vlanConfig = {
              Id = v.L3VNI.vlan;
            };
          })
        ]
        ++ (map (x: [
          (nameValuePair "${x.vlanIF}" {
            netdevConfig = {
              Name = "${x.vlanIF}";
              Kind = "vlan";
              Description = "VLAN ${toString x.vlan} for ${v.name} tenant";
            };
            vlanConfig = {
              Id = x.vlan;
            };
          })
          (nameValuePair "${x.anycastGateway.IF}" {
            netdevConfig = {
              Name = "${x.anycastGateway.IF}";
              Kind = "macvlan";
              Description = "Anycast Gateway VLAN ${toString x.vlan} for ${v.name} tenant";
              MACAddress = x.anycastGateway.hwAddr;
            };
            macvlanConfig = {
              Mode = "private";
            };
          })
        ]) v.vniVlanPairs')
      ) cfg;
      genNetwork = mapAttrsToList (
        n: v:
        [
          (nameValuePair "50-${v.vrf}" {
            name = "${v.vrf}";
          })
          (nameValuePair "50-${v.L3VNI.brIF}" {
            networkConfig = {
              IPv6LinkLocalAddressGenerationMode = "none";
            };
            vlan = [
              "${v.L3VNI.vniIF}"
            ]
            ++ (map (x: "${x.vlanIF}") v.vniVlanPairs');
            bridgeVLANs = [ { VLAN = v.L3VNI.vlan; } ] ++ (map (x: { VLAN = x.vlan; }) v.vniVlanPairs');
            bridgeFDBs = [
              { MACAddress = v.L3VNI.hwAddr; }
            ]
            ++ (map (x: { MACAddress = x.anycastGateway.hwAddr; }) v.vniVlanPairs');
          })
          (nameValuePair "55-${v.L3VNI.vxlanIF}" {
            name = "${v.L3VNI.vxlanIF}";
            bridge = [ "${v.L3VNI.brIF}" ];
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
          })
          (nameValuePair "55-${v.L3VNI.vniIF}" {
            name = "${v.L3VNI.vniIF}";
            vrf = [ "${v.vrf}" ];
            networkConfig = {
              IPv6LinkLocalAddressGenerationMode = "none";
            };
          })
        ]
        ++ map (x: [
          (
            nameValuePair "60-${x.vlanIF}" {
              name = "${x.vlanIF}";
              vrf = [ "${v.vrf}" ];
              macvlan = [ "${x.anycastGateway.IF}" ];
            }
            // optionalAttrs (x.address != "") {
              address = [ x.address ];
            }
          )
          (nameValuePair "60-${x.anycastGateway.IF}" {
            name = "${x.anycastGateway.IF}";
            vrf = [ "${v.vrf}" ];
            address = [ "${x.anycastGateway.address}" ];
          })
        ]) v.vniVlanPairs'
      ) cfg;
    in
    {
      assertions = [
        {
          assertion = config.systemd.network.enable;
          message = "This module need to enable systemd.network.enable option.";
        }
      ];
      systemd = {
        network = {
          netdevs = listToAttrs (flatten genNetdevs);
          networks = listToAttrs (flatten genNetwork);
        };
        services.set-vni-vlan-tunneling =
          let
            perPair = L3VNI: vni: vid: ''
              bridge vlan add dev ${L3VNI} vid ${vid}
              bridge vni add dev ${L3VNI} vni ${vni}
              bridge vlan add dev ${L3VNI} vid ${vid} tunnel_info id ${vni}
            '';
            perTenant =
              n: v:
              let
                L3VNI = "${v.name}-vxlan";
              in
              ''
                echo "Configuring VNI VLAN tunneling for ${v.name} tenant ..."
                ${perPair L3VNI (toString v.L3VNI.vni) (toString v.L3VNI.vlan)}
                ${concatStringsSep "\n" (map (x: perPair L3VNI (toString x.vni) (toString x.vlan)) v.vniVlanPairs')}
              '';
          in
          {
            path = with pkgs; [
              gnused
              iproute2
            ];
            wantedBy = [ "multi-user.target" ];
            wants = [ "network-online.target" ];
            after = [ "network-online.target" ];
            script = ''
              echo "Configuring VXLAN VLAN tunneling ..."
              ${concatStringsSep "\n" (mapAttrsToList perTenant cfg)}
              echo "Configured VNI VLAN tunneling."
            '';
          };
      };
    };
}
