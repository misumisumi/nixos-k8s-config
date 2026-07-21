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
  inherit (lib) hasAttr optionalAttrs;
in
{
  networking.firewall.allowedTCPPorts = config.services.openssh.ports;
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    startWhenNeeded = false;
    settings = {
      KbdInteractiveAuthentication = true;
      PasswordAuthentication = isDev;
      X11Forwarding = false;
      PermitRootLogin = if isDev then "yes" else "no";
    };
  }
  // optionalAttrs (hasAttr "manageIP" static.${group}.${hostname}) {
    listenAddresses = [
      {
        addr = static.${group}.${hostname}.manageIP;
        port = 22;
      }
    ];
  };
}
