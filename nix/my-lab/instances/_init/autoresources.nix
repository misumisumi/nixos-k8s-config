# Automatically provide these arguments to modules:
#NOTE: See https://github.com/NixOS/nixpkgs/blob/f9c6dd42d98a5a55e9894d82dc6338ab717cda23/lib/modules.nix#L75-L95
{
  self,
  ...
}:
{
  _module.args =
    let
      inherit (builtins) pathExists getEnv;
      useSecrets = pathExists "${getEnv "PWD"}/.useSecrets";
    in
    rec {
      secretsPath = if useSecrets then self + "/.secrets" else self + "/.dummy";
      configPath = secretsPath + "/config.toml";
    };
}
