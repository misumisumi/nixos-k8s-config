{ self, hostname, ... }:
{
  imports = [
    self.nixosModules.netboot
  ];
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
        #NOTE: manage network assumes ethernet
        "20-manage" = {
          name = "en*";
          DHCP = "yes";
        };
      };
    };
  };
}
