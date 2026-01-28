{
  systemd.network = {
    # netdevs = {
    #   "" = {};
    # };
    networks = {
      "10-wan.network" = {
        name = "eth0";
        networkConfig = {
          DHCP = "ipv6";
          IPv6AcceptRA = "yes";
          IPv6PrivacyExtensions = "no";
        };
        dhcpV6Config = {
          UseAddress = true;
          UseDelegatedPrefix = true;
          PrefixDelegationHint = "::/56";
        };
        ipv6AcceptRAConfig = {
          DHCPv6Client = "always";
        };
      };
    };
  };
}
