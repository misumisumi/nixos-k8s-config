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
        enable = true;
        timeout = 120; # Disable wait online
        anyInterface = false;
      };
    };
  };
  networking = {
    nftables.enable = true;
    firewall.enable = true;
    useNetworkd = true;
    useHostResolvConf = false;
    hostName = hostname;
    useDHCP = mkDefault false; # Setting each network interafces
  };
  # system.nssModules = lib.mkForce [];
}
