{
  lib,
  static,
  ...
}:
let
  inherit (lib)
    filterAttrs
    hasAttr
    mapAttrs'
    nameValuePair
    ;
  manageIPOf = h:
    if hasAttr "manageIP" h then
      h.manageIP
    else if hasAttr "networks" h && hasAttr "manage" h.networks then
      lib.removeNetmask h.networks.manage.address
    else
      null;
  hosts = filterAttrs (n: v: manageIPOf v != null) (static.compute // static.switch);
in
{
  networking.hosts = mapAttrs' (
    n: v:
    nameValuePair "${manageIPOf v}" [
      "${n}"
      "${n}.home"
    ]
  ) hosts;
}
