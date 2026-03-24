{
  systemd = {
    network = {
      enable = true;
      networks = {
        #NOTE: manage network assumes ethernet
        "20-manage" = {
          name = "eth*";
          DHCP = "yes";
        };
      };
    };
  };
}
