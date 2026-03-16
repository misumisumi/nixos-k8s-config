{
  services.cockpit = rec {
    enable = true;
    port = 9090;
    openFirewall = true;
    allowed-origins = [ "https://*:${toString port}" ];
    settings = {
      WebService = {
        AllowMultiHost = true;
      };
    };
  };
  systemd.tmpfiles.rules = [
    "d /etc/cockpit/machines.d 0766 root root -"
  ];
}
