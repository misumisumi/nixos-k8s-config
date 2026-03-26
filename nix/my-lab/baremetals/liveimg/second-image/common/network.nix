{
  lib,
  pkgs,
  hostname,
  ...
}:
let
  inherit (lib) mkForce;
in
{
  services.nscd = {
    enable = true;
  };
  networking = {
    useNetworkd = true;
    hostName = hostname;
    hosts = mkForce { };
    firewall.enable = false;
  };
  system.activationScripts.mkRandomHostName.text = ''
    echo "Create hostname"
    ${pkgs.diceware}/bin/diceware -n 2 --no-caps -d - > /etc/hostname
  '';
}
