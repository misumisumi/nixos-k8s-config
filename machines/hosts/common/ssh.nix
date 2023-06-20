{config, ...}:
# Allow yourself to SSH to the machines using your public key
let
  # read the first file that exists
  # filenames: list of paths
  readFirst = filenames:
    builtins.readFile
    (builtins.head (builtins.filter builtins.pathExists filenames));

  sshKey = readFirst [~/.ssh/id_ed25519.pub ~/.ssh/id_rsa.pub];
in {
  boot.initrd.network = {
    enable = true;
    ssh = {
      enable = true;
      authorizedKeys = [sshKey];
      hostKeys = [
        "/etc/secrets/initrd/ssh_host_rsa_key"
        "/etc/secrets/initrd/ssh_host_ed25519_key"
      ];
    };
  };
  users.users.root.openssh.authorizedKeys.keys = [sshKey];
  users.users.cardinal.openssh.authorizedKeys.keys = [sshKey];

  networking.firewall.allowedTCPPorts = config.services.openssh.ports;
  programs.ssh = {
    askPassword = "";
  };
  services.openssh = {
    enable = true;
    extraConfig = ''
      UsePAM yes
    '';
    settings = {
      KbdInteractiveAuthentication = true;
      X11Forwarding = true;
    };
  };
}