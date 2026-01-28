{ hostname, ... }:
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
    netdevs = {
      dummy0 = {
        netdevConfig = {
          Name = "dummy0";
          Kind = "dummy";
        };
      };
      veth0 = {
        netdevConfig = {
          Name = "veth0";
          Kind = "macvtap";
        };
        extraConfig = ''
          [MACVTAP]
          Mode=bridge
        '';
      };
      veth1 = {
        netdevConfig = {
          Name = "veth1";
          Kind = "macvtap";
        };
        extraConfig = ''
          [MACVTAP]
          Mode=bridge
        '';
      };
    };
    networks = {
      "5-dummy0" = {
        name = "dummy0";
        address = [ "172.16.0.1/32" ];
      };
      "10-enp5s0" = {
        name = "enp5s0";
        macvtap = [ "veth0" ];
      };
      "10-enp6s0" = {
        name = "enp6s0";
        macvtap = [ "veth1" ];
      };
      "20-veth0" = {
        name = "veth0";
        networkConfig = {
          IPv6AcceptRA = true;
        };
      };
      "20-veth1" = {
        name = "veth1";
        networkConfig = {
          IPv6AcceptRA = true;
        };
      };
    };
  };
}
