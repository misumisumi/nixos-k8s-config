{

  boot = {
    kernelModules = [
      "ip6_tunnel"
    ];
  };
  systemd.network = {
    netdevs = {
      v6plus-tnl = {
        netdevConfig = {
          Name = "v6plus-tnl";
          Kind = "ip6tnl";
        };
        tunnelConfig = {
          Mode = "ipip6";
          Local = "fd42:3a98:dc40:52c6::100";
          Remote = "fd42:3a98:dc40:52c6::254";
          DiscoverPathMTU = true;
          EncapsulationLimit = "none";
        };
      };
    };
    networks = {
      "10-enp0s4" = {
        name = "enp0s4";
        networkConfig = {
          Description = "WAN Interface";
          IPv6AcceptRA = true;
          LinkLocalAddressing = "ipv6";
          DHCP = "ipv6";
          DHCPServer = "yes";
        };
        DHCP = "ipv6";
        tunnel = [ "v6plus-tnl" ];
        address = [ "fd42:3a98:dc40:52c6::100/64" ];
      };
      "11-v6plus-tnl" = {
        name = "v6plus-tnl";
        networkConfig = {
          Description = "IPv6+ Tunnel Interface";
          IPv4Forwarding = true;
        };
        address = [ "203.0.113.1/32" ];
        routes = [
          {
            Destination = "0.0.0.0/0";
          }
        ];
      };
    };
  };
}
