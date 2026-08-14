{ hostname, ... }:
{
  services = {
    nscd = {
      enable = true;
    };
  };
  networking = {
    hostName = "${hostname}";
  };
  systemd.network = {
    enable = true;
    networks = {
      #NOTE: manage network assumes ethernet
      "20-manage" = {
        matchConfig = {
          Name = [
            "en*"
            "eno*"
            "eth*"
          ];
        };
        DHCP = "yes";
      };
    };
  };
}
