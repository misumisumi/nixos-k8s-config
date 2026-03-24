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
}
