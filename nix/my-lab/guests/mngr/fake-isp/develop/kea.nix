{
  services.kea = {
    dhcp6 = {
      enable = true;
      settings = {
        interfaces-config = {
          interfaces = [ "enp6s0" ];
        };
        lease-database = {
          name = "/var/lib/kea/dhcp6.leases";
          persist = true;
          type = "memfile";
        };
        preferred-lifetime = 3000;
        rebind-timer = 2000;
        renew-timer = 1000;
        subnet6 = [
          {
            id = 1;
            pd-pools = [
              {
                prefix = "2001:db8:fed0::";
                prefix-len = 48;
                delegated-len = 56;
              }
            ];
            subnet = "2001:db8:ffff::/64";
          }
        ];
        valid-lifetime = 4000;
      };
    };
  };
}
