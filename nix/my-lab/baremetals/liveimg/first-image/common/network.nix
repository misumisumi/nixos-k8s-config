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
}
