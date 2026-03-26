# Automatically provide these arguments to modules:
#NOTE: See https://github.com/NixOS/nixpkgs/blob/f9c6dd42d98a5a55e9894d82dc6338ab717cda23/lib/modules.nix#L75-L95
{
  lib,
  hostname,
  group,
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
      specificSecretPatch = secretPath + "/guests/${group}/${hostname}";
      static = (importTOML ../../static.toml).${group}.${hostname} or { };
    };
}
