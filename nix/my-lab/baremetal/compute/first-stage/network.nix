let
  VFT_TableID = 200;
in
{
  services = {
    nscd = {
      enable = true;
    };
    frr = {
      ospf6d = {
        enable = true;
      };
      config = ''
        vfr mgmt
          ipv6 router ospf ${VFT_TableID}
            log-adjacency-changes
            # Auto generate a router-id based on the link-local ipv4 address

        interface bond-en
          ipv6 ospf6 cost 10
          ipv6 ospf6 area 1.1.1.1

        interface bond-ib
          ipv6 ospf6 area 1.1.1.1
          ipv6 ospf6 cost 1       # Prefer ib over en
      '';
    };
  };
  systemd = {
    network = {
      netdevs = {
        "bond-en" = {
          netDevConfig = {
            kind = "bond";
          };
          bondCOnfig = {
            Mode = "active-backup";
            MIIMonitorSec = "1s";
            PrimaryReselectPolicy = "always";
            UpDelaySec = "0";
            DownDelaySec = "0";
          };
        };
        "bond-ib" = {
          netDevConfig = {
            kind = "bond";
          };
          bondCOnfig = {
            Mode = "active-backup";
            MIIMonitorSec = "1s";
            PrimaryReselectPolicy = "always";
            UpDelaySec = "0";
            DownDelaySec = "0";
          };
        };
        "vrf-mgmt" = {
          netDevConfig = {
            kind = "vrf";
          };
          vrfConfig = {
            Table = VFT_TableID;
          };
        };
      };
      networks = {
        "10-en" = {
          name = "en*";
          bond = [ "bond-en" ];
        };
        "10-ib" = {
          name = "ib*";
          bond = [ "bond-en" ];
        };
        "20-bond-en" = {
          name = "bond-en";
          vrf = [ "vrf-mgmt" ];
          networkConfig = {
            DHCP = "no";
            LinkLocalAddressing = "yes"; # Generate a link-local address for ipv4 and ipv6
          };
        };
        "20-bond-ib" = {
          name = "bond-en";
          vrf = [ "vrf-mgmt" ];
          networkConfig = {
            DHCP = "no";
            LinkLocalAddressing = "yes"; # Generate a link-local address for ipv4 and ipv6
          };
        };
      };
    };
  };
}
