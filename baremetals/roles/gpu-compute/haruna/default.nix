{
  nixpkgs.hostPlatform = "aarch64-linux";
  # nixpkgs.hostPlatform = "x86_64-linux";
  users = {
    groups.sumi = { };
    users.sumi = {
      isNormalUser = true;
      group = "sumi";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOCGcY4v0aRzAO+hLnGhEaU7JArt/Wrn8FuIgFcovlad sumi@mother-2021-03-12"
      ];
    };
  };
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    hostKeys = [
      {
        type = "rsa";
        bits = 4096;
        path = "/etc/ssh/ssh_host_rsa_key";
        openSSHFormat = true;
      }
      {
        type = "ed25519";
        path = "/etc/ssh/ssh_host_ed25519_key";
        comment = "dgx-spark-2026-09-02";
      }
    ];
    settings = {
      KbdInteractiveAuthentication = true;
      PasswordAuthentication = false;
      X11Forwarding = false;
      PermitRootLogin = "no";
    };
  };
}
