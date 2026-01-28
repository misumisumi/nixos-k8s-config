{ pkgs, lib, ... }:
{
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.default.rp_filter" = 0;
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv6.conf.default.forwarding" = 1;
  };
  networking = {
    hostName = "router";
    useNetworkd = true;
    useDHCP = false;
    firewall.enable = false;
  };
  services.openssh = {
    enable = true;
    # startWhenNeeded = true;
    ports = [ 22 ];
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
      # PermitEmptyPasswords = true;
      # UsePAM = false;
    };
  };
  # users.users.nixos = {
  #   isNormalUser = true;
  #   password = "nixos";
  #   initialPassword = "nixos";
  #   # openssh.authorizedKeys = [ ];
  # };
  users.users.root = {
    password = "nixos";
    initialPassword = "nixos";
    # openssh.authorizedKeys = [ ];
  };
  systemd.network = {
    netdevs = {
      # "enp5s0.manage" = {
      #   netdevConfig = {
      #     Kind = "vlan";
      #     Name = "enp5s0.manage";
      #   };
      #   vlanConfig = {
      #     Id = "20";
      #   };
      # };
      # "br-10g.main" = {
      #   netdevConfig = {
      #     Kind = "bridge";
      #     Name = "br-10g.main";
      #   };
      # };
      # "br-10g.manage" = {
      #   netdevConfig = {
      #     Kind = "vlan";
      #     Name = "br-10g.manage";
      #   };
      #   vlanConfig = {
      #     Id = "20";
      #   };
      # };
      # "br-40g.main" = {
      #   netdevConfig = {
      #     Kind = "bridge";
      #     Name = "br-40g.main";
      #   };
      # };
      dummy0 = {
        netdevConfig = {
          Name = "dummy0";
          Kind = "dummy";
        };
      };
    };
    # links = {
    #   "10-enp0s3" = {
    #     matchConfig = {
    #       MACAddress = "6d:b1:48:b4:a2:3c";
    #     };
    #     linkConfig = {
    #       Name = "enp0s3";
    #     };
    #   };
    #   "10-enp0s4" = {
    #     matchConfig = {
    #       MACAddress = "47:0a:de:79:c8:06";
    #     };
    #     linkConfig = {
    #       Name = "enp0s4";
    #     };
    #   };
    # };
    networks = {
      "10-dummy0" = {
        name = "dummy0";
        address = [ "172.16.0.2/32" ];
      };
      "20-enp0s3" = {
        name = "enp0s3";
        networkConfig = {
          IPv6AcceptRA = true;
        };
      };
      "20-enp0s4" = {
        name = "enp0s4";
        networkConfig = {
          IPv6AcceptRA = true;
        };
      };
      # "10-enp0s3" = {
      #   name = "enp0s3";
      # };
      # "10-enp0s4" = {
      #   name = "enp0s4";
      # };
      # "20-eth-10g" = {
      #   matchConfig.name = [
      #     "enp6s0"
      #     "vm_10g"
      #   ];
      #   bridge = [ "br-10g.main" ];
      # };
      # "20-eth-40g" = {
      #   matchConfig.name = [
      #     "enp7s0"
      #     "vm_40g"
      #   ];
      #   bridge = [ "br-40g.main" ];
      # };
      # "25-br-10g.main" = {
      #   name = "br-10g.main";
      #   vlan = [ "br-10g.manage" ];
      #   networkConfig = {
      #     LinkLocalAddressing = "ipv6";
      #     IPv6StableSecretAddress = "fe80::4471:ccc7:eff2:54bb";
      #   };
      # };
      # "25-br-40g.main" = {
      #   name = "br-40g.main";
      #   networkConfig = {
      #     LinkLocalAddressing = "ipv6";
      #     IPv6StableSecretAddress = "fe80::7029:ad26:6093:e4dc";
      #   };
      # };
    };
  };
}
