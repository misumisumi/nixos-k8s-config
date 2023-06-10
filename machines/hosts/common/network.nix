{
  lib,
  config,
  hostname,
  ...
}: {
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
    useDHCP = lib.mkDefault false; # Setting each network interafces
    firewall = {
      enable = true;
      trustedInterfaces = [
        "br0"
      ];
      allowedTCPPorts =
        [
        ]
        + config.services.openssh.ports;
    };
  };

  services = {
    nscd = {
      enable = true;
    };
    resolved = {
      enable = true;
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