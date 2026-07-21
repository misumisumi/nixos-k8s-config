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
in
{
  networking.hosts = mapAttrs' (
    n: v:
    nameValuePair "${v.manageIP}" [
      "${n}"
      "${n}.home"
    ]
  ) (filterAttrs (n: v: hasAttr "manageIP" v) (static.compute // static.switch));
}
