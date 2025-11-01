{
  hostname,
  lan_ip,
  lan_ipv6,
  ...
}:
{
  networking = {
    hostName = hostname;
    useNetworkd = true;
    firewall = {
      enable = true;
      filterForward = true;
      extraForwardRules = ''
        iifname eth1 oifname eth0 accept
      '';
    };
    nftables = {
      enable = true;
      # tables = { };
    };
  };
  services.resolved.enable = false;
  systemd = {
    network = {
      enable = true;
      networks = {
        "10-wan" = {
          name = "eth0";
          DHCP = "yes";
        };
        "10-lan" = {
          name = "eth1";
          address = [
            "${lan_ip}/24"
            "${lan_ipv6}/64"
          ];
        };
      };
    };
  };
}
