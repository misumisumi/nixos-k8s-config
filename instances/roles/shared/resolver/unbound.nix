{ static, ... }:
{
  networking = {
    nameservers = [
      "127.0.0.1"
      "::1"
    ];
    nftables.enable = true;
    firewall = {
      allowedTCPPorts = [
        53 # DNS
        8081 # PowerDNS API
      ];
      allowedUDPPorts = [
        53 # DNS
      ];
    };
  };
  services = {
    resolved.enable = false;
    unbound = {
      enable = true;
      settings = {
        server = {
          interface = [ "0.0.0.0" ];
          port = "53";
          access-control = [
            "0.0.0.0/0 refuse"
          ]
          ++ static.shared.resolver.acl;
          access-control-view = [ ];
          domain-insecure = [ "home" ];
          private-domain = [ "home" ];
          auto-trust-anchor-file = "/var/lib/unbound/root.key";
          # ── メモリ・キャッシュの最適化（1GB〜2GB RAM用） ──
          num-threads = "2";
          msg-cache-size = "64m";
          rrset-cache-size = "128m";
          infra-cache-numhosts = "10000";
        };
        stub-zone = {
          name = "home";
          stub-addr = "${static.shared.dns.manageIP}";
        };
      };
    };
  };
}
