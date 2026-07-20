{ inputs, config, ... }:
let
  inherit (config.networking.vxlan) tenants;

  routerId = "10.10.10.50";
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
        address = [ "172.16.100.5/24" ];
        routes = [
          {
            Destination = "0.0.0.0/0";
            Gateway = "172.16.100.1";
            Metric = 100;
          }
        ];
      };
    };
  };
}
