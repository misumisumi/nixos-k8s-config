{
  boot = {
    kernel.sysctl = {
      "net.ipv4.conf.all.rp_filter" = 0;
      "net.ipv4.conf.default.rp_filter" = 0;
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
      "net.ipv6.conf.default.forwarding" = 1;
    };
    kernelModules = [
      "ip6_tunnel"
    ];
  };
  systemd.network = {
    netdevs = {
    };
  };
}
