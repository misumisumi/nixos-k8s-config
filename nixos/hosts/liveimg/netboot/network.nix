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
      networks = {
        "10-wired" = {
          name = "en*";
          DHCP = "yes";
        };
      };
    };
  };
}
