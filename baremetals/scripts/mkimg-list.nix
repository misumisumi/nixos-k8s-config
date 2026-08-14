{
  extension ? "zst",
}:
let
  pkgs = import <nixpkgs> { };
  lib = pkgs.lib.extend (import ../patches/lib.nix);
  inherit (builtins) getEnv hasAttr;
  inherit (lib)
    filterAttrs
    mapAttrs
    attrValues
    mapAttrsToList
    listToAttrs
    flatten
    ;
  jsonFormat = pkgs.formats.json { };
  static = lib.mergeStatic (getEnv "STATIC_DIR") (
    if getEnv "STATIC_PROD" == "1" then "static.nix" else "static_dev.nix"
  );
  formated = mapAttrs (
    n: v:
    mapAttrsToList (n': v': {
      name = v'.uuid;
      value = {
        hostname = "${n'}";
        image = "${n'}/nixos-kexec.tar.${extension}";
      };
    }) (filterAttrs (n'': v'': hasAttr "uuid" v'') v)
  ) static;
in
jsonFormat.generate "kexec-images.json" (
  listToAttrs (flatten (attrValues (filterAttrs (n: v: v != [ ]) formated)))
)
