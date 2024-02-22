# Automatically provide these arguments to modules:
# See: https://github.com/NixOS/nixpkgs/blob/f9c6dd42d98a5a55e9894d82dc6338ab717cda23/lib/modules.nix#L75-L95
{ pkgs
, name
, ...
}:
let
  # inherit (pkgs.callPackage ../../utils/consts.nix { }) nodeIP virtualIP;
  inherit (pkgs.callPackage ../../utils/resources.nix { }) resourcesByRole outputsByRole nodeIP;
  inherit (pkgs.callPackage ../../utils/consts.nix { }) virtualIP;
  # `colmena` initially evaluates all tags for nix.
  # Dummies are used at this time, since an error will occur if the corresponding tag is not found in the output json of `terraform`.
  # This eliminates errors but complicates debugging.
  get_resource = builtins.filter (r: r.values.name == name) (resourcesByRole name "nfs");
  self = if get_resource == [ ] then { values.ipv4_address = "dummy"; } else builtins.head get_resource;
  get_output = builtins.filter (r: r.name == name) (outputsByRole name "nfs");
in
{
  _module.args = {
    inherit (pkgs.callPackage ../../utils/consts.nix { }) workspace constByKey;
    inherit (pkgs.callPackage ../../utils/resources.nix { }) resources resourcesByRole resourcesByRoles;
    nodeIP = nodeIP self;
    hostID = if get_output == [ ] then "dummyid0" else (builtins.head get_output).host_id;
    virtualIP = virtualIP "nfs";
  };
}
