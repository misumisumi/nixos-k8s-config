{ pkgs, ... }: {
  users.users = {
    nixos = {
      isNormalUser = true;
      shell = pkgs.bashInteractive;
      extraGroups = [
        "wheel"
      ];
      useDefaultShell = true;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOCGcY4v0aRzAO+hLnGhEaU7JArt/Wrn8FuIgFcovlad sumi@mother-2021-03-12"
      ];
      password = "nixos";
    };
    root = {
      password = "nixos";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOCGcY4v0aRzAO+hLnGhEaU7JArt/Wrn8FuIgFcovlad sumi@mother-2021-03-12"
      ];
    };
  };
}
