{ lib, ... }:
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
    hostName = mkDefault "";
    useNetworkd = true;
    useHostResolvConf = false;
    useDHCP = mkDefault true; # Setting each network interafces
    firewall.checkReversePath = "loose";
  };
  # system.nssModules = lib.mkForce [];
}
