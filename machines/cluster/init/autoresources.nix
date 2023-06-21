# Automatically provide these arguments to modules:
# * `self` - terraform resource for this node
#   i.e. libvirt_domain where resource.name == name (as defined in the hive)
# * `resources` - a list of all libvirt_domain resources
# * `resourcesByRole` - function that returns resources with the given prefix
#
# See: https://github.com/NixOS/nixpkgs/blob/f9c6dd42d98a5a55e9894d82dc6338ab717cda23/lib/modules.nix#L75-L95
{
  pkgs,
  name,
  ...
}: {
  _module.args = rec {
    inherit (pkgs.callPackage ../../../utils/resources.nix {}) resources resourcesByRole resourcesByRoles;
    inherit (pkgs.callPackage ../../../utils/consts.nix {}) virtualIP workspace;
    inherit (import ../../../utils/utils.nix) nodeIP;
    self = builtins.head (builtins.filter (r: r.values.name == name) resources);
  };
}