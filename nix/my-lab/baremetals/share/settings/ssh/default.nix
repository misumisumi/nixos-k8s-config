{
  config,
  user,
  secretPath,
  ...
}:
# Allow yourself to SSH to the machines using your public key
let
  sshKey = "${secretPath}/users/${user}/ssh/id_ed25519.pub";
in
{
  networking.firewall.allowedTCPPorts = config.services.openssh.ports;
  # users.users.root.openssh.authorizedKeys.keyFiles = [ sshKey ];
  # users.users.${user}.openssh.authorizedKeys.keyFiles = [ sshKey ];
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      KbdInteractiveAuthentication = true;
      X11Forwarding = false;
      PasswordAuthentication = true;
    };
  };
}
