{
  lib,
  pkgs,
  hostname,
  ...
}:
{
  services = {
    nscd = {
      enable = true;
    };
  };
  networking = {
    useNetworkd = true;
    hostName = hostname;
    hosts = lib.mkForce { };
    useDHCP = false;
    firewall.enable = false;
  };
  system.activationScripts.mkRandomHostName.text = ''
    echo "Create hostname"
    ${pkgs.diceware}/bin/diceware -n 2 --no-caps -d - > /etc/hostname
  '';
}
