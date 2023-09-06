# Automatically provide these arguments to modules:
# See: https://github.com/NixOS/nixpkgs/blob/f9c6dd42d98a5a55e9894d82dc6338ab717cda23/lib/modules.nix#L75-L95
{ pkgs
, name
, ...
}:
let
  inherit (pkgs.callPackage ../../utils/consts.nix { }) nodeIP virtualIP;
in
{
  _module.args = {
    inherit (pkgs.callPackage ../../utils/consts.nix { }) workspace nodeIPsByRole nodeIPsByRoles;
    nodeIP = nodeIP name;
    virtualIP = virtualIP "k8s";
  };
}