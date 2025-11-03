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
    {
      pxeInet = rec {
        ip = "10.10.0.${suffix}";
        ipv6 = "fd42:3a98:dc40:10::${suffix}";
        ip_prefix = "/24";
        ipv6_prefix = "/64";
        base_ip = removeSuffix ".${suffix}" ip;
        base_ipv6 = removeSuffix "::${suffix}" ipv6;
      };
      kexecInet = rec {
        ip = "10.20.0.${suffix}";
        ipv6 = "fd42:3a98:dc40:20::${suffix}";
        ip_prefix = "/24";
        ipv6_prefix = "/64";
        base_ip = removeSuffix ".${suffix}" ip;
        base_ipv6 = removeSuffix "::${suffix}" ipv6;
      };
    };
}
