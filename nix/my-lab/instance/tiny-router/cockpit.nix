{
  services.cockpit = rec {
    enable = true;
    port = 9090;
    openFirewall = true;
    allowed-origins = [ "https://*:${builtins.toString port}" ];
    settings = {
      WebService = {
        AllowMultiHost = true;
      };
    };
  };
}
