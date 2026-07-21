{
  extension ? "zst",
}:
let
  pkgs = import <nixpkgs> { };
  inherit (builtins) getEnv hasAttr;
  inherit (pkgs.lib)
    importTOML
    filterAttrs
    mapAttrs
    attrValues
    mapAttrsToList
    listToAttrs
    flatten
    ;
  jsonFormat = pkgs.formats.json { };
  static = importTOML (getEnv "STATIC_FILE");
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
