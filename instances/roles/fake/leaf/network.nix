{
  inputs,
  config,
  static,
  group,
  tag,
  ...
}:
let
  inherit (config.networking.vxlan) tenants;
  inherit (static.${group}.${tag}.bgp) k8sSegmentIP routerId;
in
{
  imports = [
    inputs.homelab-modules.nixosModules.vlan-aware-vxlan
  ];
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.default.rp_filter" = 0;
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv6.conf.default.forwarding" = 1;
  };
  networking = {
    useNetworkd = true;
    firewall.enable = false;
    vxlan.tenants = {
      k8s = {
        name = "k8s";
        L3VNI = {
          hwAddr = "46:9f:a8:f5:8c:6c";
          vni = 11001;
          vlan = 1101;
          local = "${routerId}";
          destinationPort = 4789;
        };
      };
      vault = {
        name = "vault";
        L3VNI = {
          hwAddr = "46:9f:a8:f5:8c:6d";
          vni = 11002;
          vlan = 1102;
          local = "${routerId}";
          destinationPort = 4789;
        };
      };
      proxy = {
        name = "proxy";
        L3VNI = {
          hwAddr = "46:9f:a8:f5:8c:6e";
          vni = 11003;
          vlan = 1103;
          local = "${routerId}";
          destinationPort = 4789;
        };
      };
      shared = {
        name = "shared";
        L3VNI = {
          hwAddr = "46:9f:a8:f5:8c:6f";
          vni = 11004;
          vlan = 1104;
          local = "${routerId}";
          destinationPort = 4789;
        };
      };
    };
  };
  systemd.network = {
    enable = true;
    netdevs = {
      lo0 = {
        netdevConfig = {
          Name = "lo0";
          Kind = "dummy";
        };
      };
    };
    networks = {
      "5-lo0" = {
        name = "lo0";
        address = [
          "${routerId}/32"
        ];
        routes = [
          {
            Destination = "10.10.10.0/24";
          }
        ];
      };
      "15-enp5s0" = {
        name = "enp5s0";
      };
      "20-enp6s0" = {
        name = "enp6s0";
        vrf = [ "${tenants.k8s.vrf}" ];
        DHCP = "no";
        address = [ "${k8sSegmentIP}/24" ];
        routes = [
          {
            Destination = "0.0.0.0/0";
            Gateway = "172.16.100.1";
            Metric = 100;
          }
        ];
      };
      "20-enp7s0" = {
        name = "enp7s0";
        vrf = [ "${tenants.vault.vrf}" ];
        DHCP = "no";
        address = [ "172.16.11.254/24" ];
        routes = [
          {
            Destination = "0.0.0.0/0";
            Gateway = "172.16.11.100";
            Metric = 100;
          }
        ];
      };
      "20-enp8s0" = {
        name = "enp8s0";
        vrf = [ "${tenants.proxy.vrf}" ];
        DHCP = "no";
        address = [ "172.16.10.254/24" ];
        routes = [
          {
            Destination = "0.0.0.0/0";
            Gateway = "172.16.10.100";
            Metric = 100;
          }
        ];
      };
      "20-enp9s0" = {
        name = "enp9s0";
        vrf = [ "${tenants.shared.vrf}" ];
        DHCP = "no";
        address = [ "172.16.1.253/24" ];
        routes = [
          {
            Destination = "0.0.0.0/0";
            Gateway = "172.16.1.100";
            Metric = 100;
          }
        ];
      };
    };
  };
}
