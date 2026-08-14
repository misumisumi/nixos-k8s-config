{
  hostname,
  static,
  group,
  ...
}:
let
  inherit (static.${group}) virtualIPs;
  inherit (static.${group}.${hostname}) networks;
in
{
  virtualisation.incus.preseed = {
    # config = {
    #   "cluster.offline_threshold" = 20;
    # };
    cluster = {
      server_name = "${hostname}";
      enabled = true;
    };
  };
  services.frr = {
    vrrpd.enable = true;
    config = ''
      interface ${networks.manage.IF}
       vrrp 5 version 3
       vrrp 5 priority 200
       vrrp 5 advertisement-interval 1500
       vrrp 5 ip ${virtualIPs.incus.address}
    '';
  };
  systemd.network = {
    netdevs = {
      vrrp4-incus = {
        netdevConfig = {
          Name = "vrrp4-incus";
          Kind = "macvlan";
          MACAddress = "00:00:5e:00:01:05"; # VRRP MAC address for VRID 5
        };
        macvlanConfig = {
          Mode = "bridge";
        };
      };
    };
    networks = {
      "10-manage".macvlan = [ "vrrp4-incus" ];
      "20-vrrp4-incus" = {
        name = "vrrp4-incus";
        networkConfig = {
          Description = "VRRP for Ajisai";
        };
        address = [ "${virtualIPs.incus.address}/${virtualIPs.incus.cidr}" ];
      };
    };
  };
}
