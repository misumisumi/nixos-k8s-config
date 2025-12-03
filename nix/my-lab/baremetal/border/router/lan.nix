{
  systemd.network = {
    networks = {
      "20-lan.network" = {
        name = "eth1";
        networkConfig = {
          Address = "192.168.2.1/24";
          IPv6SendRA = true;
          IPv6AcceptRA = false;
          DHCPPrefixDelegation = true;
        };
        ipv6SendRAConfig = {
          Managed = true;
          OtherInformation = true;
        };
        ipv6Prefixes = [
          {
            Prefix = "::/64";
            PreferredLifetimeSec = 3600;
            ValidLifetimeSec = 7200;
          }
        ];
        dhcpPrefixDelegationConfig = {
          SubnetId = 1;
          Announce = true;
        };
      };
    };
  };
}
