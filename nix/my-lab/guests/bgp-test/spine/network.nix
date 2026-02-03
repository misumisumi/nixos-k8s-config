{
  lib,
  hostname,
  switch_id,
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
    };
    networks = {
      "5-lo0" = {
        name = "lo0";
        address = [
          "10.1.254.${switch_id}/32"
        ];
      };
    }
    // (
      let
        inherit (lib)
          range
          listToAttrs
          nameValuePair
          ;
        interfaces = map (
          x:
          let
            x' = toString x;
            remoteAS = toString (x - 1);
          in
          nameValuePair "10-enp${x'}s0" {
            name = "enp${x'}s0";
            address = [ "192.168.12${remoteAS}.1/30" ];
          }
        ) (range 5 8);
      in
      listToAttrs interfaces
    );
  };
}
