{
  config,
  ...
}:
# Allow yourself to SSH to the machines using your public key
{
  networking.firewall.allowedTCPPorts = config.services.openssh.ports;
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      KbdInteractiveAuthentication = true;
      PasswordAuthentication = false;
      X11Forwarding = false;
      permitRootLogin = false;
    };
  };
}
