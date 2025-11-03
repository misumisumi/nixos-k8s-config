{
  services.cockpit = {
    enable = true;
    port = 9090;
    openFirewall = true;
    settings = {
      WebService = {
        AllowMultiHost = true;
      };
    };
  };
}
