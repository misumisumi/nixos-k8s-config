# Automatically provide these arguments to modules:
#NOTE: See https://github.com/NixOS/nixpkgs/blob/f9c6dd42d98a5a55e9894d82dc6338ab717cda23/lib/modules.nix#L75-L95
{
  lib,
  group,
  user,
  isDev,
  ...
}:
{
  _module.args =
    let
      inherit (lib) importTOML;
    in
    rec {
      secretPath = ../../../secrets + "${if isDev then "/develop" else "/production"}";
      groupSecretPath = secretPath + "/roles/${group}";
      userSecretPath = secretPath + "/user/${user}";
      static = if isDev then importTOML ../../static_dev.toml else importTOML ../../static.toml;
    };
}
