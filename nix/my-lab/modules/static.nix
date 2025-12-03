# Automatically provide these arguments to modules:
#NOTE: See https://github.com/NixOS/nixpkgs/blob/f9c6dd42d98a5a55e9894d82dc6338ab717cda23/lib/modules.nix#L75-L95
{
  self,
  lib,
  hostname,
  type,
  ...
}:
{
  _module.args =
    let
      inherit (builtins) pathExists getEnv;
      inherit (lib) importTOML;
      useSecrets = pathExists "${getEnv "PWD"}/.useSecrets";
    in
    rec {
      secretPath = if useSecrets then self + "/.secrets" else self + "/.dummy";
      staticConfigPath = secretPath + "/${type}/${hostname}/static.toml";
      static = importTOML staticConfigPath;
    };
}
