{
  static,
  config,
  ...
}:
let
  inherit (static.microvm.borderRouter) BR CE IPIP6_IPv4;
  inherit (static.microvm.borderRouter.bgp) wanVrfTable;
  vrf = "wan-vrf${toString wanVrfTable}";
  wanIF = static.microvm.borderRouter.networks.wan.IF;
in
{
  boot = {
    kernel.sysctl = {
      "net.ipv6.conf.all.accept_ra" = 1;
      "net.ipv6.conf.${wanIF}.accept_ra" = 2;
    };
    kernelModules = [ "ip6_tunnel" ];
  };
  networking.firewall.extraInputRules = ''
    meta l4proto ipv6-icmp accept
    iifname "${wanIF}" meta l4proto 4 accept
    iifname "${wanIF}" udp dport 546 udp sport 547 accept
  '';
  systemd.network = {
    netdevs.v6plus-tnl = {
      netdevConfig = {
        Name = "v6plus-tnl";
        Kind = "ip6tnl";
      };
      tunnelConfig = {
        Mode = "ipip6";
        Local = "${CE}";
        Remote = "${BR}";
        DiscoverPathMTU = true;
        EncapsulationLimit = "none";
      };
    };
    networks = {
      "10-wan" = {
        name = wanIF;
        vrf = [ vrf ];
        linkConfig = {
          MTUBytes = static.microvm.borderRouter.networks.wan.mtu;
        };
        networkConfig = {
          Description = "WAN Interface";
          IPv6AcceptRA = true;
          LinkLocalAddressing = "ipv6";
          DHCPPrefixDelegation = true;
        };
        DHCP = "ipv6";
        tunnel = [ "v6plus-tnl" ];
        address = [ "${CE}/128" ];
        dhcpV6Config = {
          DUIDType = "link-layer";
          WithoutRA = "solicit";
          PrefixDelegationHint = "::/56";
          RapidCommit = false;
          SendHostname = false;
        };
      };
      "11-v6plus-tnl" = {
        name = "v6plus-tnl";
        vrf = [ vrf ];
        linkConfig = {
          MTUBytes = static.microvm.borderRouter.networks.wan.mtu - 40;
        };
        networkConfig = {
          Description = "IPv6+ Tunnel Interface";
          IPv4Forwarding = true;
        };
        address = [ "${IPIP6_IPv4}/32" ];
        routes = [
          {
            Destination = "0.0.0.0/0";
          }
        ];
      };
    };
  };
}
