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
        timeout = 5; # Disable wait online
        anyInterface = true;
      };
    };
  };
  networking = {
    nftables.enable = true;
    firewall = {
      enable = false;
    };
    useNetworkd = true;
    useHostResolvConf = false;
    hostName = hostname;
    useDHCP = mkDefault false; # Setting each network interafces
  };
  # system.nssModules = lib.mkForce [];
}
