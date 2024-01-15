{ lib
, config
, stateVersion
, user
, ...
}:
let
  # read the first file that exists
  # filenames: list of paths
  readFirst = filenames:
    builtins.readFile
      (builtins.head (builtins.filter builtins.pathExists filenames));

  sshKey = readFirst [ ~/.ssh/id_ed25519.pub ~/.ssh/id_rsa.pub ];
in
{

  networking.firewall.allowedTCPPorts = config.services.openssh.ports;
  users.users.root.openssh.authorizedKeys.keys = [ sshKey ];
  users.users.${user}.openssh.authorizedKeys.keys = [ sshKey ];
  programs.ssh = {
    askPassword = "";
  };
  services.openssh =
    {
      enable = true;
      ports = [ 22 ];
      extraConfig = ''
        UsePAM yes
      '';
    }
    // lib.attrsets.optionalAttrs (stateVersion <= "22.11") {
      kbdInteractiveAuthentication = true;
      forwardX11 = false;
    }
    // lib.attrsets.optionalAttrs (stateVersion > "22.11") {
      settings = {
        KbdInteractiveAuthentication = true;
        X11Forwarding = false;
      };
    };
}
