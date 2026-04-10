{
  services.linstor = {
    client.enable = true;
    satellite.enable = true;
    controller.enable = true;
    cluster = {
      HA = {
        enable = true;
      };
      nodes = {
        ajisai = {
          address = "10.1.254.5";
          type = "combined";
        };
        mao = {
          address = "10.1.254.6";
          type = "combined";
        };
        satsuki = {
          address = "10.1.254.7";
          type = "combined";
        };
      };
    };
  };
}
