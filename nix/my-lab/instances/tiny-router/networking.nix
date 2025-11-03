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
      "${pxeInet.lan_ip}" = [ hostname ];
      # "${lan_ipv6}" = [ hostname ];
    }
    // optionalAttrs (pxeInet.lan_ip != kexecInet.lan_ip) {
      "${kexecInet.lan_ip}" = [ hostname ];
    };
    useNetworkd = true;
    firewall = {
      enable = true;
      filterForward = true;
      extraForwardRules = ''
        iifname eth1 oifname eth0 accept
      '';
    };
    nftables = {
      enable = true;
      # tables = { };
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
          "vrf-${kexecVLAN}" = {
            netdevConfig = {
              Kind = "vrf";
              Name = "vrf-${kexecVLAN}";
            };
            vrfConfig = {
              Table = toInt kexecVLAN;
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
            vlan = [ "eth1.${kexecVLAN}" ];
            address = [
              "${pxeInet.lan_ip}/24"
              "${pxeInet.lan_ipv6}/64"
            ];
          };
          "20-lan.210" = {
            name = "eth1.${kexecVLAN}";
            # vrf = [ "vrf-${kexecVLAN}" ];
            address = [
              "${kexecInet.lan_ip}/24"
              "${kexecInet.lan_ipv6}/64"
            ];
          };
        };
      };
  };
}
