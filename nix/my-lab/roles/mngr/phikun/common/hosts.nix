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
    removeSuffix
    ;
in
{
  networking.hosts = mapAttrs' (
    n: v:
    nameValuePair "${removeSuffix "/24" v.manageIP}" [
      "${n}"
      "${n}.home"
    ]
  ) (filterAttrs (n: v: hasAttr "manageIP" v) (static.compute // static.switch));
}
