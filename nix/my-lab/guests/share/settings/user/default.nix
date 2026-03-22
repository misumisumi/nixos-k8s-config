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
  inherit (lib.attrsets) optionalAttrs;
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
    password = "nixos";
  };
  users.users.root.password = "nixos";
  # // lib.optionalAttrs (hasAttr "password" config.sops.userHashedPassword) {
  #   hashedPasswordFile = config.sops.secrets.userHashedPassword.password.path;
  # };
  # users.users.root.hashedPasswordFile =
  #   optionalAttrs (hasAttr "password" config.sops.rootHashedPassword)
  #     {
  #       hashedPasswordFile = config.sops.secrets.rootHashedPassword.path;
  #     };
}
