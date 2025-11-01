# Automatically provide these arguments to modules:
# See: https://github.com/NixOS/nixpkgs/blob/f9c6dd42d98a5a55e9894d82dc6338ab717cda23/lib/modules.nix#L75-L95
{
  lib,
  ...
}:
{
  _module.args =
    let
      inherit (lib) removeSuffix;
      suffix = "1";
    in
    rec {
      lan_ip = "10.10.0.${suffix}";
      lan_ipv6 = "fd42:3a98:dc40:60c1::${suffix}";
      lan_base_ip = removeSuffix ".${suffix}" lan_ip;
      lan_base_ipv6 = removeSuffix "::${suffix}" lan_ipv6;
    };
}
