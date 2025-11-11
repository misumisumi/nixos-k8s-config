{
  stdenvNoCC,
  lib,
  buildEnv,
  fetchgit,
  fetchurl,
  fetchFromGitHub,
  dockerTools,
  ansible,
}:
/*
    Install ansible collections
  *
  * Collections are downloaded, then each collection is installed with:
  * $ ansible-galaxy collection install <collection.tar.gz>.
  *
  * The resulting derivation is the ansible collections path.
  *
  * Example:
  *
  * ANSIBLE_COLLECTIONS_PATH = "${callPackage ./ansible-collections.nix {}}/ansible_collections"
*/
let
  collectionSources = import ../_sources/generated.nix {
    inherit
      fetchgit
      fetchurl
      fetchFromGitHub
      dockerTools
      ;
  };

  collectionDerivation =
    name:
    stdenvNoCC.mkDerivation {
      inherit (collectionSources."${name}") pname version src;

      nativeBuildInputs = [ ansible ];
      phases = [ "installPhase" ];

      installPhase = ''
        mkdir -p $out
        ANSIBLE_HOME=$TMPDIR ansible-galaxy collection install $src -p $TMPDIR
        mv $TMPDIR/ansible_collections/* $out/
      '';
    };
  roleDerivation =
    name:
    stdenvNoCC.mkDerivation rec {
      pname = collectionSources."${name}".aname;
      inherit (collectionSources."${name}") version src;

      phases = [
        "unpackPhase"
        "installPhase"
      ];

      installPhase = ''
        mkdir -p $out/${pname}
        cp -r ./* $out/${pname}/
        echo "version: ${version}" > $out/${pname}/meta/.galaxy_install_info
      '';
    };

  collections = lib.mapAttrsToList (name: value: collectionDerivation name) (
    lib.filterAttrs (n: v: lib.hasPrefix "collection-" n) collectionSources
  );
  roles = lib.mapAttrsToList (name: value: roleDerivation name) (
    lib.filterAttrs (n: v: lib.hasPrefix "role-" n) collectionSources
  );
in
{
  collections = buildEnv {
    name = "ansible-collections";
    paths = collections;
  };
  roles = buildEnv {
    name = "ansible-roles";
    paths = roles;
  };
}
