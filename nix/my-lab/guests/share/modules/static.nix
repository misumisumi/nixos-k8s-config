# Automatically provide these arguments to modules:
#NOTE: See https://github.com/NixOS/nixpkgs/blob/f9c6dd42d98a5a55e9894d82dc6338ab717cda23/lib/modules.nix#L75-L95
{
  self,
  lib,
  hostname,
  group,
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
      secretPath = ../../../secrets + "${if useSecrets then "/product" else "/dummy"}";
      specificSecretPatch = secretPath + "/guests/${group}/${hostname}";
      static = (importTOML ../../static.toml).${group}.${hostname} or { };
    };
}
