{
  lib,
  static,
  group,
  hostname,
  ...
}:
let
  inherit (lib) optional removeNetmask;

  wan = static.${group}.${hostname}.networks.wan;
  wanIF = wan.IF;
  # static.nix に address があれば静的 IP、なければ DHCP（本番=ens3 DHCP / dev=lab 静的 IP）
  wanNetwork =
    if wan ? address then
      {
        matchConfig.Name = wanIF;
        networkConfig = {
          Description = "WAN interface (static)";
          IPv4Forwarding = true;
        };
        address = [ wan.address ];
        routes = optional (wan ? gateway) {
          Destination = "0.0.0.0/0";
          Gateway = wan.gateway;
        };
      }
    else
      {
        matchConfig.Name = wanIF;
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
        };
        dhcpV4Config.UseDomains = true;
      };
in
{
  systemd.network.networks."10-wan" = wanNetwork;

  networking = {
    nftables = {
      enable = true;
      tables."manage-web-ui" = {
        family = "inet";
        content = ''
          chain prerouting {
            type nat hook prerouting priority dstnat; policy accept;
            # トンネル発 443 のみ管理UIへ。daddr条件で「公衆網IP宛ssh-over-443(フルtunnel時)」を保護
            iifname "tailscale0" ip daddr 100.64.0.1 tcp dport 443 redirect to :9443
          }
        '';
      };
    };
    firewall = {
      enable = true;
      allowedTCPPorts = [
        443
      ];
      # WireGuard control plane: 51820 直接 + 443（sslh 経由）
      allowedUDPPorts = [
        51820
        443
      ];
      # Pi-hole DNS + dashboard are reachable only over the tunnel (wg0 + tailscale0).
      interfaces.wg0 = {
        allowedUDPPorts = [ 53 ]; # for DNS
        allowedTCPPorts = [ 9443 ]; # nginx: TLS reverse proxy for managing web-ui
      };
      interfaces.tailscale0 = {
        allowedUDPPorts = [ 53 ]; # for DNS (Tailscale クライアント用)
        allowedTCPPorts = [ 9443 ]; # Headplane (Tailscale クライアント用)
      };
    };
  };
}
