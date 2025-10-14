# Allow yourself to SSH to the machines using your public key
let
  inherit (builtins)
    filter
    getEnv
    head
    pathExists
    readFile
    ;
  # read the first file that exists
  # filenames: list of paths
  readFirst = filenames: readFile (head (filter pathExists filenames));

  sshKey = readFirst [
    "${getEnv "HOME"}/.ssh/id_ed25519.pub"
    "${getEnv "HOME"}/.ssh/id_rsa.pub"
  ];
in
{ config, user, ... }:
{
  networking.firewall.allowedTCPPorts = config.services.openssh.ports;
  users.users.root.openssh.authorizedKeys.keys = [ sshKey ];
  users.users.${user}.openssh.authorizedKeys.keys = [ sshKey ];
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
