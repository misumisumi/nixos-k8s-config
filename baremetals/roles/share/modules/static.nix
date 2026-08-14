# Automatically provide these arguments to modules:
#NOTE: See https://github.com/NixOS/nixpkgs/blob/f9c6dd42d98a5a55e9894d82dc6338ab717cda23/lib/modules.nix#L75-L95
{
  lib,
  hostname,
  group,
  user,
  isDev,
  ...
}:
{
  _module.args =
    let
      staticFile = if isDev then "static_dev.nix" else "static.nix";
      static = lib.mergeStatic ../.. staticFile;
    in
    rec {
      secretPath = ../../../secrets + "${if isDev then "/develop" else "/production"}";
      hostSecretPath = secretPath + "/roles/${group}/${hostname}";
      userSecretPath = secretPath + "/users/${user}";
      inherit static;
    };
}
