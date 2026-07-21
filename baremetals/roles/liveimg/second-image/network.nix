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
  systemd.network = {
    enable = true;
    networks = {
      "20-en" = {
        matchConfig = {
          Name = [
            "en*"
            "eth*"
          ];
        };
        DHCP = "yes";
      };
    };
  };
  system.activationScripts.mkRandomHostName.text = ''
    echo "Create hostname"
    ${pkgs.diceware}/bin/diceware -n 2 --no-caps -d - > /etc/hostname
  '';
}
