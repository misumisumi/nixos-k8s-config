{ ... }: {
  systemd = {
    network = {
      enable = true;
      wait-online = {
        timeout = 5; # Disable wait online
        anyInterface = true;
      };
    };
  };

  services = {
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
      ];
    };
  };
}
