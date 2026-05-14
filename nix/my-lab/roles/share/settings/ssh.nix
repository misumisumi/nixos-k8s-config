{
  lib,
  config,
  static,
  group,
  hostname,
  isDev,
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
      PasswordAuthentication = isDev;
      X11Forwarding = false;
      PermitRootLogin = if isDev then "yes" else "no";
    };
  };
}
