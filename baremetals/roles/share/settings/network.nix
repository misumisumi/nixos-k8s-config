{ lib, hostname, ... }:
let
  inherit (lib) mkDefault;
in
{
  services.nscd.enable = true;
  systemd = {
    network = {
      enable = mkDefault true;
      wait-online = {
        timeout = 30;
        anyInterface = true;
      };
    };
  };
  networking = {
    useNetworkd = true;
    useHostResolvConf = false;
    hostName = hostname;
    useDHCP = mkDefault false; # Setting each network interafces
    firewall.checkReversePath = "loose";
  };
  # system.nssModules = lib.mkForce [];
}
