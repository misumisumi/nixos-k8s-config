{
  lib,
  static,
  ...
}:
let
  inherit (static.microvm.borderRouter) routerId;
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
  systemd = {
    network = {
      netdevs = {
        lo0 = {
          netdevConfig = {
            Name = "lo0";
            Kind = "dummy";
          };
        };
      };
      # // networkConf4LAN.netdevs;
      networks = {
        "5-lo0" = {
          name = "lo0";
          address = [
            "${routerId}/32"
          ];
        };
        "15-enp0s3" = {
          name = "enp0s3";
          networkConfig = {
            Description = "Point to Point link";
          };
        };
      };
    };
  };
}
