{
  lib,
  config,
  static,
  group,
  hostname,
  ...
}:
let
  inherit (lib) removeSuffix;
  inherit (static.${group}.${hostname}) manageIP;
in
{
  networking.firewall.allowedTCPPorts = config.services.openssh.ports;
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    listenAddresses = [
      {
        addr = removeSuffix "/24" manageIP;
        port = 22;
      }
    ];
    startWhenNeeded = false;
    settings = {
      KbdInteractiveAuthentication = true;
      PasswordAuthentication = true;
      X11Forwarding = false;
      PermitRootLogin = "yes";
    };
  };
}
