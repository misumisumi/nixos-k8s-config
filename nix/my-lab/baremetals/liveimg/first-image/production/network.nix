{ lib, pkgs, ... }:
{
  services = {
    nscd = {
      enable = true;
    };
  };
  networking = {
    hostName = lib.mkForce "";
    hosts = lib.mkForce { };
    useDHCP = false;
    firewall.enable = false;
  };
  system.activationScripts.mkRandomHostName.text = ''
    echo "Create hostname"
    ${pkgs.diceware}/bin/diceware -n 2 --no-caps -d - > /etc/hostname
  '';
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
