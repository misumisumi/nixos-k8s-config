# Single VXLAN Device supporting Multiple VLAN Aware Bridges
{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib)
    assertMsg
    any
    concatStringsSep
    filter
    flatten
    head
    listToAttrs
    mapAttrsToList
    mkOption
    nameValuePair
    optional
    optionalAttrs
    optionalString
    splitString
    toInt
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
                default = "none";
                description = "MAC address for tenant VXLAN interfaces.";
              };
              vni = mkOption {
                type = types.int;
                apply = toString;
                description = "VXLAN Network Identifier (VNI).";
              };
              vlan = mkOption {
                type = types.int;
                apply = toString;
                default = 1;
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
              mode = mkOption {
                type = types.enum [
                  "vlan-aware"
                  "l3-only"
                  "single-vni"
                ];
                default = "vlan-aware";
                description = ''
                  Bridge and VXLAN mode for this tenant.

                  - `vlan-aware`: VLAN-aware single VXLAN device with the
                    configured `vniVlanPairs` (default).
                  - `l3-only`: only the L3VNI (no L2VNI/VLAN pairs). Use this on
                    a border/PE that terminates the tenant VRF but has no local
                    L2 access ports.
                  - `single-vni`: legacy single-VNI VXLAN device without VLAN
                    filtering (no L3VNI SVI is created).
                '';
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
              transitVnis = mkOption {
                type = types.listOf (
                  types.submodule {
                    options = {
                      vni = mkOption {
                        type = types.int;
                        apply = toString;
                        description = "VXLAN Network Identifier (VNI).";
                      };
                      remoteVteps = mkOption {
                        type = types.listOf types.str;
                        default = [ ];
                        description = "Underlay IP addresses of remote VTEPs advertising the transit VNI.";
                      };
                    };
                  }
                );
                default = [ ];
                description = ''
                  Additional L3VNIs owned by other tenants that this VTEP must be able
                  to encapsulate towards (direct leaf-to-leaf inter-tenant routing).
                  Each VNI is registered on the tenant VXLAN interface and a static FDB
                  entry is added for every remote VTEP.
                '';
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
                  apply = toString;
                  description = "VXLAN Network Identifier (VNI).";
                };
                vlan = mkOption {
                  type = types.int;
                  apply = toString;
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
          default = [ ];
          description = ''
            List of VNI and VLAN ID pairs of tenant
            VNI must be unique across the tenants.
            VLAN ID is not unique across the tenants.
          '';
        };
        isolation = mkOption {
          default = { };
          description = "Inter-VLAN isolation policy for this tenant.";
          type = types.submodule {
            options = {
              allowed = mkOption {
                type = types.listOf (
                  types.submodule {
                    options = {
                      from = mkOption {
                        type = types.int;
                        description = "Source VLAN ID.";
                      };
                      to = mkOption {
                        type = types.listOf types.int;
                        default = [ ];
                        description = "Destination VLAN IDs allowed from the source VLAN.";
                      };
                    };
                  }
                );
                default = [ ];
                description = ''
                  Directional inter-VLAN allowances.
                  All other inter-VLAN traffic within this tenant is dropped.
                '';
              };
              extraRule = mkOption {
                type = types.lines;
                default = "";
                description = ''
                  Additional nftables rules for this tenant.

                  The rules are inserted into the tenant-isolation forward chain before
                  the generated drop rules, so they can be used for explicit exceptions.
                '';
                example = ''iifname "home-vlan100" ip daddr 192.168.20.10 accept'';
              };
            };
          };
        };
        vniVlanPairs' = mkOption {
          type = types.listOf (
            types.submodule {
              options = {
                vni = mkOption {
                  type = types.str;
                  description = "VXLAN Network Identifier (VNI).";
                };
                vlan = mkOption {
                  type = types.str;
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
        vrf = config.name + "-vrf${config.L3VNI.vni}";
        L3VNI = {
          vniIF = config.name + "-vni${config.L3VNI.vni}";
          brIF = config.name + "-br";
          vxlanIF = config.name + "-vxlan";
        };
        vniVlanPairs' = map (
          x:
          let
            IFName = config.name + "-vlan${x.vlan}";
          in
          {
            inherit (x) vni vlan address;
            vlanIF = IFName;
            anycastGateway = optionalAttrs (x.anycastGateway != { }) {
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
  imports = [ ./tenant-isolation.nix ];
  options = {
    networking.vxlan.tenants = mkOption {
      type = types.attrsOf configPerTenant;
      description = "Configuration for Single VXLAN Device supporting Multiple VLAN Aware Bridges.";
    };
  };
  config =
    let
      # vlan-aware / l3-only はどちらも VLAN aware な single VXLAN デバイスを使う。
      # l3-only は L2VNI/VLAN pair を持たない点だけが異なる。
      isVlanAware = v: v.L3VNI.mode != "single-vni";
      hasPairs = v: v.L3VNI.mode == "vlan-aware";

      genNetdevs = mapAttrsToList (
        n: v:
        [
          (nameValuePair "${v.L3VNI.brIF}" {
            netdevConfig = {
              Name = "${v.L3VNI.brIF}";
              Kind = "bridge";
              Description = "Bridge for ${v.name} tenant";
              MACAddress = v.L3VNI.hwAddr;
            };
            bridgeConfig = optionalAttrs (isVlanAware v) {
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
            }
            // optionalAttrs (!(isVlanAware v)) {
              VNI = toInt v.L3VNI.vni;
            }
            // optionalAttrs (isVlanAware v) {
              VNIFilter = true;
              External = true;
            };
          })
          (nameValuePair "${v.vrf}" {
            netdevConfig = {
              Name = "${v.vrf}";
              Kind = "vrf";
              Description = "VRF for ${v.name} tenant";
            };
            vrfConfig = {
              Table = toInt v.L3VNI.vni;
            };
          })
        ]
        ++ optional (isVlanAware v) (
          nameValuePair "${v.L3VNI.vniIF}" {
            netdevConfig = {
              Name = "${v.L3VNI.vniIF}";
              Kind = "vlan";
              Description = "VLAN ${v.L3VNI.vlan} for ${v.name} tenant";
              MACAddress = v.L3VNI.hwAddr;
            };
            vlanConfig = {
              Id = toInt v.L3VNI.vlan;
            };
          }
        )
        ++ (map (x: [
          (nameValuePair "${x.vlanIF}" {
            netdevConfig = {
              Name = "${x.vlanIF}";
              Kind = "vlan";
              Description = "VLAN ${x.vlan} for ${v.name} tenant";
            };
            vlanConfig = {
              Id = toInt x.vlan;
            };
          })
          (nameValuePair "${x.anycastGateway.IF}" {
            netdevConfig = {
              Name = "${x.anycastGateway.IF}";
              Kind = "macvlan";
              Description = "Anycast Gateway VLAN ${x.vlan} for ${v.name} tenant";
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
          (nameValuePair "50-${v.L3VNI.brIF}" (
            {
              name = "${v.L3VNI.brIF}";
              vrf = [ "${v.vrf}" ];
            }
            // optionalAttrs (isVlanAware v) {
              networkConfig = {
                IPv6LinkLocalAddressGenerationMode = "none";
              };
              vlan = [
                "${v.L3VNI.vniIF}"
              ]
              ++ (map (x: "${x.vlanIF}") v.vniVlanPairs');
              bridgeVLANs = [
                { VLAN = toInt v.L3VNI.vlan; }
              ]
              ++ (map (x: { VLAN = toInt x.vlan; }) v.vniVlanPairs');
              bridgeFDBs =
                let
                  macAddresses =
                    assert assertMsg (
                      !(v.L3VNI.hwAddr == "none" && (any (x: x.anycastGateway != { })) v.vniVlanPairs')
                    ) "Anycast gateway mac address must be specified when anycast gateway is configured.";
                    if v.L3VNI.hwAddr == "none" then
                      [ ]
                    else
                      [
                        { MACAddress = v.L3VNI.hwAddr; }
                      ]
                      ++ (map (x: { MACAddress = x.anycastGateway.hwAddr; }) v.vniVlanPairs');
                in
                macAddresses;
            }
          ))
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
            extraConfig = optionalString (isVlanAware v) ''
              [Bridge]
              VLANTunnel=yes
            '';
          })
        ]
        ++ optional (isVlanAware v) (
          nameValuePair "55-${v.L3VNI.vniIF}" {
            name = "${v.L3VNI.vniIF}";
            vrf = [ "${v.vrf}" ];
            networkConfig = {
              IPv6LinkLocalAddressGenerationMode = "none";
            };
          }
        )
        ++ map (x: [
          (nameValuePair "60-${x.vlanIF}" {
            name = "${x.vlanIF}";
            vrf = [ "${v.vrf}" ];
            macvlan = [ "${x.anycastGateway.IF}" ];
            address = optional (x.address != "") x.address;
          })
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
            perTransit = L3VNI: t: ''
              bridge vni add dev ${L3VNI} vni ${t.vni}
              ${concatStringsSep "\n" (
                map (
                  ip: "bridge fdb append 00:00:00:00:00:00 dev ${L3VNI} dst ${ip} vni ${t.vni} self"
                ) t.remoteVteps
              )}
            '';
            perTenant =
              n: v:
              let
                L3VNI = "${v.name}-vxlan";
              in
              optionalString (isVlanAware v) ''
                echo "Configuring VNI VLAN tunneling for ${v.name} tenant ..."
                ${perPair L3VNI v.L3VNI.vni v.L3VNI.vlan}
                ${concatStringsSep "\n" (map (x: perPair L3VNI x.vni x.vlan) v.vniVlanPairs')}
                ${concatStringsSep "\n" (map (t: perTransit L3VNI t) v.L3VNI.transitVnis)}
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
            serviceConfig = {
              Restart = "on-failure";
              RestartSec = "5";
            };
            unitConfig = {
              # 5回失敗したら諦める (初回 + リトライ4回)
              StartLimitBurst = 5;
              StartLimitIntervalSec = 3600;
            };
            script = ''
              echo "Configuring VXLAN VLAN tunneling ..."
              ${concatStringsSep "\n" (mapAttrsToList perTenant cfg)}
              echo "Configured VNI VLAN tunneling."
            '';
          };
        # ゾーン用 VLAN インターフェースの SVI アドレスは systemd-networkd が
        # 非同期に付与する。このサービスは全テナントの SVI アドレスが
        # 現れるまで待つ (DNS/DHCP 等がアドレスへの bind を試みる前に)。
        # network-online.target は wait-online 無効のため実際には待たない。
        services.wait-vlan-addresses =
          let
            # 各テナントの SVI (interface:address) の一覧 (address 無しは除外)
            entries = flatten (
              mapAttrsToList (
                _: v:
                map (x: "${x.vlanIF}:${head (splitString "/" x.address)}") (
                  filter (x: x.address != "") v.vniVlanPairs'
                )
              ) cfg
            );
          in
          {
            description = "Wait for tenant VLAN SVI addresses to be assigned";
            wants = [ "systemd-networkd.service" ];
            after = [ "systemd-networkd.service" ];
            path = with pkgs; [
              coreutils
              gnugrep
              iproute2
            ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            script = ''
              for entry in ${concatStringsSep " " entries}; do
                iface=''${entry%%:*}
                addr=''${entry#*:}
                for _ in $(seq 1 120); do
                  if ip -4 addr show dev "$iface" 2>/dev/null | grep -Fq "$addr/"; then
                    break
                  fi
                  sleep 1
                done
                if ! ip -4 addr show dev "$iface" 2>/dev/null | grep -Fq "$addr/"; then
                  echo "wait-vlan-addresses: address $addr on $iface did not appear" >&2
                  exit 1
                fi
              done
            '';
          };
        services.set-vlan-arp-flux =
          let
            interfaces = flatten (
              mapAttrsToList (_: v: map (x: x.vlanIF) v.vniVlanPairs') cfg
            );
          in
          {
            description = "Configure ARP behavior for tenant VLAN SVIs";
            wantedBy = [ "multi-user.target" ];
            wants = [ "wait-vlan-addresses.service" ];
            after = [ "wait-vlan-addresses.service" ];
            path = with pkgs; [
              procps
            ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            script = ''
              ${concatStringsSep "\n" (
                map (iface: ''
                  sysctl -w net.ipv4.conf.${iface}.arp_ignore=1
                  sysctl -w net.ipv4.conf.${iface}.arp_announce=2
                '') interfaces
              )}
            '';
          };
      };
    };
}
