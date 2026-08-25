{
  lib,
  static,
  group,
  hostname,
  ...
}:
let
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
        routes = lib.optional (wan ? gateway) {
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

  # VPN clients need to reach the internet through the tunnel.
  boot.kernel.sysctl."net.ipv4.ip_forward" = true;
  networking.nat = {
    enable = true;
    externalInterface = wanIF;
    internalInterfaces = [ "wg0" ];
  };

  networking = {
    nftables.enable = true;
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
      # Pi-hole DNS + dashboard are reachable only over the tunnel (wg0).
      interfaces.wg0 = {
        allowedUDPPorts = [ 53 ];
        allowedTCPPorts = [ 8080 ];
      };
    };
  };
}
