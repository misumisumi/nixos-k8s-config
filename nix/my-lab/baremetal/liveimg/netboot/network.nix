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

  systemd = {
    network = {
      enable = true;
      networks = {
        "10-wired" = {
          name = "en*";
          DHCP = "yes";
        };
      };
    };
  };
}
