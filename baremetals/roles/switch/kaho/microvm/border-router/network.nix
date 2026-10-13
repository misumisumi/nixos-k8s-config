{
  lib,
  static,
  config,
  ...
}:
let
  inherit (builtins) substring;
  inherit (lib)
    fixedWidthString
    splitString
    sublist
    toHexString
    toLower
    ;
  inherit (config.networking.vxlan) tenants;
  inherit (static.microvm.borderRouter.bgp) routerId;

  # border-leaf を集約したため、ゾーンの per-VTEP SVI は従来どおり .253 を維持する。
  # (router-id は 10.10.10.254 に変更したため SVI サフィックスは固定値とする)
  idSuffix = "253";

  hwAddrPart =
    vid:
    let
      vidToHex = fixedWidthString 4 "0" (toLower (toHexString vid));
    in
    substring 0 2 vidToHex + ":" + substring 2 2 vidToHex;

in
{
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.default.rp_filter" = 0;
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv6.conf.default.forwarding" = 1;
  };
  networking = {
    firewall.enable = true;
    nftables.enable = true;
    hostName = "router";
    useNetworkd = true;
    useDHCP = false;
  };
  services.resolved = {
    enable = lib.mkDefault true;
    settings.Resolve = {
      DNSSEC = lib.mkDefault "false";
      FallbackDNS = [
        "1.1.1.1"
        "2606:4700:4700::1111"
        "8.8.8.8"
        "2001:4860:4860::8888"
      ];
    };
  };
  networking.vxlan.tenants = {
    "wan" = {
      name = "wan";
      L3VNI = {
        vni = 30001;
        local = routerId;
        destinationPort = 4780;
      };
    };
    "home" = {
      name = "home";
      L3VNI = {
        hwAddr = "3F:E9:45:18:AD:4B";
        vni = 11001;
        vlan = 1101;
        local = routerId;
        destinationPort = 4789;
      };
      vniVlanPairs = [
        {
          vni = 11010;
          vlan = 10;
          address = "192.168.10.${idSuffix}/24";
          anycastGateway = {
            hwAddr = "03:03:aa:aa:${hwAddrPart 10}";
            address = "192.168.10.254/24";
          };
        }
      ];
    };
    "iot" = {
      name = "iot";
      L3VNI = {
        hwAddr = "3F:E9:45:18:AD:4C";
        vni = 11002;
        vlan = 1102;
        local = routerId;
        destinationPort = 4789;
      };
      vniVlanPairs = [
        {
          vni = 11020;
          vlan = 20;
          address = "192.168.20.${idSuffix}/24";
          anycastGateway = {
            hwAddr = "03:03:aa:aa:${hwAddrPart 20}";
            address = "192.168.20.254/24";
          };
        }
      ];
    };
    "gst" = {
      name = "gst";
      L3VNI = {
        hwAddr = "3F:E9:45:18:AD:4D";
        vni = 11003;
        vlan = 1103;
        local = routerId;
        destinationPort = 4789;
      };
      vniVlanPairs = [
        {
          vni = 11100;
          vlan = 100;
          address = "192.168.100.${idSuffix}/24";
          anycastGateway = {
            hwAddr = "03:03:aa:aa:${hwAddrPart 100}";
            address = "192.168.100.254/24";
          };
        }
      ];
    };
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
        };
      };
      "lo${tenants.wan.L3VNI.vni}" = {
        netdevConfig = {
          Name = "lo${tenants.wan.L3VNI.vni}";
          Kind = "dummy";
        };
      };
    };
    networks = {
      "5-lo0" = {
        name = "lo0";
        address = [
          "${tenants.home.L3VNI.local}/32"
        ];
      };
      "5-lo${tenants.wan.L3VNI.vni}" = {
        name = "lo${tenants.wan.L3VNI.vni}";
        vrf = [ "${tenants.wan.vrf}" ];
        address = [
          "${tenants.home.L3VNI.local}/32"
        ];
      };
      # BGP unnumbered の underlay リンク (ホスト側 br_router2host)
      "15-enp0s5" = {
        name = "enp0s5";
        networkConfig = {
          Description = "To host interface (BGP unnumbered underlay)";
          IPv6AcceptRA = false;
        };
      };
    };
  };
}
