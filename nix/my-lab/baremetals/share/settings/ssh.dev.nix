{
  config,
  ...
}:
{
  networking.firewall.allowedTCPPorts = config.services.openssh.ports;
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      KbdInteractiveAuthentication = true;
      PasswordAuthentication = true;
      X11Forwarding = false;
      PermitRootLogin = "yes";
    };
  };
}
