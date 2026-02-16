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
  systemd.network =
    let
      inherit (builtins)
        foldl'
        ;
      inherit (lib)
        range
        mkMerge
        ;
      mergeAttrsListRecursive =
        attrsList: foldl' (merged: attrs: lib.recursiveUpdate merged attrs) { } attrsList;

      loopbackIFs = [
        {
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
                "10.1.254.1/32"
              ];
            };
            "5-enp7s0" = {
              name = "enp7s0";
              networkConfig = {
                IPv6LinkLocalAddressGenerationMode = "none";
              };
            };
            "5-enp8s0" = {
              name = "enp8s0";
              networkConfig = {
                IPv6LinkLocalAddressGenerationMode = "none";
              };
            };
          };
        }
      ];
      underlayMacvlanIF =
        _id:
        let
          id = toString _id;
        in
        {
          netdevs = {
            "macvlan${id}" = {
              netdevConfig = {
                Name = "macvlan${toString id}";
                Kind = "macvlan";
              };
              macvlanConfig = {
                Mode = "bridge"; # NOTE: VMと通信する必要がある場合はvepaはダメ
              };
            };
          };
          networks = {
            "10-macvlan${id}" = {
              name = "macvlan${id}";
              address = [ "192.168.13${id}.1/30" ];
              # routes = [
              #   {
              #     Destination = "10.1.254.${id}";
              #     Gateway = "192.168.13${id}.2";
              #   }
              # ];
            };
          };
        };
      underlayMacvlanIFs = (map underlayMacvlanIF (range 4 5)) ++ (map underlayMacvlanIF (range 6 7));
      networkConfs = [
        {
          networks = {
            "5-enp5s0" = {
              name = "enp5s0";
              macvlan = map (x: "macvlan${toString x}") (range 4 5);
              networkConfig = {
                IPv6LinkLocalAddressGenerationMode = "none";
              };
            };
            "5-enp6s0" = {
              name = "enp6s0";
              macvlan = map (x: "macvlan${toString x}") (range 6 7);
              networkConfig = {
                IPv6LinkLocalAddressGenerationMode = "none";
              };
            };
          };
        }
      ]
      ++ underlayMacvlanIFs
      ++ loopbackIFs;
    in
    {
      config.networkConfig = {
        #NOTE: https://scottstuff.net/posts/2025/02/25/frr-vs-systemd-networkd/
        ManageForeignNextHops = false;
        ManageForeignRoutes = false;
        ManageForeignRoutingPolicyRules = false;
      };
    }
    // mergeAttrsListRecursive networkConfs;
}
