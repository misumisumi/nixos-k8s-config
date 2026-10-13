# Default normal user config
{
  user,
  pkgs,
  static,
  ...
}:
{
  users.users.${user} = {
    isNormalUser = true;
    shell = pkgs.bashInteractive;
    extraGroups = [
      "wheel"
      "uucp"
    ];
    useDefaultShell = true;
    subUidRanges = [
      # Using rootless container
      {
        count = 100000;
        startUid = 300000;
      }
    ];
    subGidRanges = [
      {
        count = 100000;
        startGid = 300000;
      }
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOCGcY4v0aRzAO+hLnGhEaU7JArt/Wrn8FuIgFcovlad sumi@mother-2021-03-12"
    ];
    password = static.users.${user}.password or "nixos";
  };

  users.users.root = {
    password = static.users.root.password or "nixos";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOCGcY4v0aRzAO+hLnGhEaU7JArt/Wrn8FuIgFcovlad sumi@mother-2021-03-12"
    ];
  };
}
