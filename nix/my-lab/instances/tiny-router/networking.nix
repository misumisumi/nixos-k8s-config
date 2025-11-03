{
  lib,
  hostname,
  pxeInet,
  kexecInet,
  ...
}:
let
  inherit (lib) optionalAttrs;
in
{
  networking = {
    hostName = hostname;
    hosts = {
      "127.0.0.2" = lib.mkForce [ ];
      "${pxeInet.ip}" = [ hostname ];
      # "${ipv6}" = [ hostname ];
    }
    // optionalAttrs (pxeInet.ip != kexecInet.ip) {
      "${kexecInet.ip}" = [ hostname ];
    };
    useNetworkd = true;
    firewall = {
      enable = true;
      filterForward = true;
      extraInputRules = lib.mkBefore ''
        iifname eth1 ip saddr ${pxeInet.base_ip}.0/24 ip daddr ${kexecInet.ip} drop
      '';
      extraForwardRules = ''
        iifname eth1 oifname eth0 tcp dport 9090 accept
      '';
    };
    nftables = {
      enable = true;
      tables = {
        "my-rule" = {
          family = "inet";
          content = ''
            ct helper tftp {
              type "tftp" protocol udp
            }

            chain rpfilter {
              type filter hook prerouting priority filter - 20;
              udp dport 69 ct helper set "tftp"
            }

            chain input {
              # Drop traffic from pxe network to kexec VLAN gateway
              type filter hook input priority filter - 10;
              ip saddr ${pxeInet.base_ip}.0${pxeInet.ip_prefix} ip daddr ${kexecInet.base_ip}.0${kexecInet.ip_prefix} drop
              ip6 saddr ${pxeInet.base_ipv6}::${pxeInet.ipv6_prefix} ip6 daddr ${kexecInet.base_ipv6}::${kexecInet.ipv6_prefix} drop

              # Drop traffic from kexec VLAN to pxe network gateway
              ip saddr ${kexecInet.base_ip}.0${kexecInet.ip_prefix} ip daddr ${pxeInet.base_ip}.0${pxeInet.ip_prefix} drop
              ip6 saddr ${kexecInet.base_ipv6}::${kexecInet.ipv6_prefix} ip6 daddr ${pxeInet.base_ipv6}::${pxeInet.ipv6_prefix} drop

              # Allow TFTP
              ct helper set "tftp" accept
            }
          '';
        };
      };
    };
  };
  services.resolved.enable = false;
  systemd = {
    network =
      let
        kexecVLAN = "210";
        inherit (lib) toInt;
      in
      {
        enable = true;
        netdevs = {
          "eth1.${kexecVLAN}" = {
            netdevConfig = {
              Kind = "vlan";
              Name = "eth1.${kexecVLAN}";
            };
            vlanConfig = {
              Id = toInt kexecVLAN;
            };
          };
        };
        networks = {
          "10-wan" = {
            name = "eth0";
            DHCP = "yes";
          };
          "10-lan" = {
            name = "eth1";
            vlan = [
              "eth1.${kexecVLAN}"
            ];
            address = [
              "${pxeInet.ip}${pxeInet.ip_prefix}"
              "${pxeInet.ipv6}${pxeInet.ipv6_prefix}"
            ];
          };
          "20-lan.210" = {
            name = "eth1.${kexecVLAN}";
            address = [
              "${kexecInet.ip}${kexecInet.ip_prefix}"
              "${kexecInet.ipv6}${kexecInet.ipv6_prefix}"
            ];
          };
        };
      };
  };
}
