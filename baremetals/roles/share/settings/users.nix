# Default normal user config
{
  config,
  lib,
  user,
  pkgs,
  ...
}:
let
  inherit (builtins) hasAttr;
  inherit (lib) optionalAttrs;
in
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
  }
  // optionalAttrs (hasAttr "password" (config.sops.userHashedPassword or { })) {
    hashedPasswordFile = config.sops.secrets.userHashedPassword.path;
  };

  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOCGcY4v0aRzAO+hLnGhEaU7JArt/Wrn8FuIgFcovlad sumi@mother-2021-03-12"
    ];
  }
  // (optionalAttrs (hasAttr "password" (config.sops.rootHashedPassword or { })) {
    hashedPasswordFile = config.sops.secrets.rootHashedPassword.path;
  });
}
