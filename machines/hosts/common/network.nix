{ hostname, ... }: {
  systemd = {
    network = {
      enable = true;
      wait-online = {
        timeout = 0; # Disable wait online
      };
    };
  };

  networking = {
    hostName = "${hostname}";
    useDHCP = true;
    firewall = {
      enable = true;
      trustedInterfaces = [
        "br0"
      ];
      allowedTCPPorts = [ ];
    };
  };

  services = {
    nscd = {
      enable = true;
    };
    resolved = {
      enable = true;
      extraConfig = ''
        [Resolve]
        DNS=1.1.1.1 2606:4700:4700::1111
      '';
      fallbackDns = [
        "1.1.1.1"
        "2606:4700:4700::1111"
        "8.8.8.8"
        "2001:4860:4860::8888"
        "192.168.1.1"
      ];
    };
  };

  # system.nssModules = lib.mkForce [];
}
