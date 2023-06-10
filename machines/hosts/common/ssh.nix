{
  lib,
  stateVersion,
  hostname,
  config,
  ...
}:
# Allow yourself to SSH to the machines using your public key
let
  # read the first file that exists
  # filenames: list of paths
  readFirst = filenames:
    builtins.readFile
    (builtins.head (builtins.filter builtins.pathExists filenames));

  sshKey = readFirst [~/.ssh/id_ed25519.pub ~/.ssh/id_rsa.pub];
in {
  programs.ssh = {
    askPassword = "";
  };

  networking.firewall.allowedTCPPorts = config.services.openssh.ports;
  users.users.root.openssh.authorizedKeys.keys = [sshKey];
  users.users."${hostname}".openssh.authorizedKeys.keys = [sshKey];
  services.openssh =
    {
      enable = true;
      extraConfig = ''
        UsePAM yes
      '';
    }
    // lib.attrsets.optionalAttrs (stateVersion <= "22.11") {
      kbdInteractiveAuthentication = true;
      forwardX11 = true;
    }
    // lib.attrsets.optionalAttrs (stateVersion > "22.11") {
      settings = {
        kbdInteractiveAuthentication = true;
        X11Forwarding = true;
      };
    };
}