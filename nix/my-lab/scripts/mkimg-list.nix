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
    hasSuffix
    ;
  jsonFormat = pkgs.formats.json { };
  static = importTOML (getEnv "STATIC_FILE");
  formated = mapAttrs (
    n: v:
    mapAttrsToList (n': v': {
      name = v'.uuid;
      value = {
        hostname = "${n'}";
        image = "kexec/${
          if (hasSuffix "dev.toml" (getEnv "STATIC_FILE")) then "develop" else "production"
        }/${n'}/nixos-kexec.tar.xz";
      };
    }) (filterAttrs (n'': v'': hasAttr "uuid" v'') v)
  ) static;
in
jsonFormat.generate "kexec-images.json" (
  listToAttrs (flatten (attrValues (filterAttrs (n: v: v != [ ]) formated)))
)
