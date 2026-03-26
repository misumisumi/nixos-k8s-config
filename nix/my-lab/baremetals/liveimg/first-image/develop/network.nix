{
  systemd = {
    network = {
      enable = true;
      networks = {
        "20-en" = {
          name = "en*";
          DHCP = "yes";
        };
      };
    };
  };
}
