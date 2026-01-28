{
  lib,
  hostname,
  static,
  ...
}:
let
  pxe = static.dnsmasq.pxe.network;
  kexec1 = static.dnsmasq.kexec1.network;
  kexec2 = static.dnsmasq.kexec2.network;
  pxeIP = "${pxe.baseIP}${pxe.suffix}";
  kexec1IP = "${kexec1.baseIP}${kexec1.suffix}";
  kexec2IP = "${kexec2.baseIP}${kexec2.suffix}";
in
{
  networking = {
    hostName = hostname;
    hosts = {
      "127.0.0.2" = lib.mkForce [ ];
      "${pxeIP}" = [ hostname ];
      "${kexec1IP}" = [ hostname ];
      "${kexec2IP}" = [ hostname ];
    };
    useNetworkd = true;
    firewall = {
      enable = true;
      filterForward = true;
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
              ip saddr ${pxe.baseIP}0${pxe.ipPrefix} ip daddr ${kexec1.baseIP}0${kexec1.ipPrefix} drop
              ip saddr ${pxe.baseIP}0${pxe.ipPrefix} ip daddr ${kexec2.baseIP}0${kexec2.ipPrefix} drop
              ip6 saddr ${pxe.baseIPv6}${pxe.ipv6Prefix} ip6 daddr ${kexec1.baseIPv6}${kexec1.ipv6Prefix} drop
              ip6 saddr ${pxe.baseIPv6}${pxe.ipv6Prefix} ip6 daddr ${kexec2.baseIPv6}${kexec2.ipv6Prefix} drop

              # Drop traffic from kexec VLAN to pxe network gateway
              ip saddr ${kexec1.baseIP}0${kexec1.ipPrefix} ip daddr ${pxe.baseIP}0${pxe.ipPrefix} drop
              ip saddr ${kexec2.baseIP}0${kexec2.ipPrefix} ip daddr ${pxe.baseIP}0${pxe.ipPrefix} drop
              ip6 saddr ${kexec1.baseIPv6}${kexec1.ipv6Prefix} ip6 daddr ${pxe.baseIPv6}${pxe.ipv6Prefix} drop
              ip6 saddr ${kexec2.baseIPv6}${kexec2.ipv6Prefix} ip6 daddr ${pxe.baseIPv6}${pxe.ipv6Prefix} drop

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
    network = {
      enable = true;
      netdevs =
        let
          inherit (lib) toInt;
        in
        {
          "br0" = {
            netdevConfig = {
              Kind = "bridge";
              Name = "br0";
            };
          };
          "br0.${kexec1.id}" = {
            netdevConfig = {
              Kind = "vlan";
              Name = "br0.${kexec1.id}";
            };
            vlanConfig = {
              Id = toInt kexec1.id;
            };
          };
          "br0.${kexec2.id}" = {
            netdevConfig = {
              Kind = "vlan";
              Name = "br0.${kexec2.id}";
            };
            vlanConfig = {
              Id = toInt kexec2.id;
            };
          };
        };
      networks = {
        "10-wan" = {
          name = "eth0";
          DHCP = "yes";
        };
        "10-eth" = {
          name = "eth1 eth2 eth3";
          bridge = [ "br0" ];
        };
        "20-pxe-service" = {
          name = "br0";
          vlan = [
            "br0.${kexec1.id}"
            "br0.${kexec2.id}"
          ];
          address = [
            "${pxeIP}${pxe.ipPrefix}"
            "${pxe.baseIPv6}${pxe.suffix}${pxe.ipv6Prefix}"
          ];
        };
        "20-kexec1-service" = {
          name = "br0.${kexec1.id}";
          address = [
            "${kexec1IP}${kexec1.ipPrefix}"
            "${kexec1.baseIPv6}${kexec1.suffix}${kexec1.ipv6Prefix}"
          ];
        };
        "20-kexec2-service" = {
          name = "br0.${kexec2.id}";
          address = [
            "${kexec2IP}${kexec2.ipPrefix}"
            "${kexec2.baseIPv6}${kexec2.suffix}${kexec2.ipv6Prefix}"
          ];
        };
      };
    };
  };
}
