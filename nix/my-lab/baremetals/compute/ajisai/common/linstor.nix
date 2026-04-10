{
  services.linstor = {
    client = {
      enable = true;
      settings = {
        global = "ajisai,mao,satsuki";
      };
    };
    satellite.enable = true;
    controller.enable = true;
  };
}
