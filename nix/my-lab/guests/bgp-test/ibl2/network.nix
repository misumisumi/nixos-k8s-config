{
  lib,
  hostname,
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
  systemd.network = {
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
          MTUBytes = 65536;
        };
      };
      "enp5s0.4" = {
        netdevConfig = {
          Name = "enp5s0.4";
          Kind = "vlan";
        };
        vlanConfig = {
          Id = 4;
        };
      };
      "enp5s0.5" = {
        netdevConfig = {
          Name = "enp5s0.5";
          Kind = "vlan";
        };
        vlanConfig = {
          Id = 5;
        };
      };
      "enp6s0.6" = {
        netdevConfig = {
          Name = "enp6s0.6";
          Kind = "vlan";
        };
        vlanConfig = {
          Id = 6;
        };
      };
      "enp6s0.7" = {
        netdevConfig = {
          Name = "enp6s0.7";
          Kind = "vlan";
        };
        vlanConfig = {
          Id = 7;
        };
      };
    };
    networks = {
      "5-lo0" = {
        name = "lo0";
        address = [
          "10.0.254.2/32"
        ];
      };
      "5-enp5s0" = {
        name = "enp5s0";
        vlan = [
          "enp5s0.4"
          "enp5s0.5"
        ];
      };
      "5-enp6s0" = {
        name = "enp6s0";
        vlan = [
          "enp6s0.6"
          "enp6s0.7"
        ];
      };
      "10-enp5s0.4" = {
        name = "enp5s0.4";
        address = [ "192.168.214.1/30" ];
      };
      "10-enp5s0.5" = {
        name = "enp5s0.5";
        address = [ "192.168.215.1/30" ];
      };
      "10-enp6s0.6" = {
        name = "enp6s0.6";
        address = [ "192.168.216.1/30" ];
      };
      "10-enp6s0.7" = {
        name = "enp6s0.7";
        address = [ "192.168.217.1/30" ];
      };
    };
  };
}
