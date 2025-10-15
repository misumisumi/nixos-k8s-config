{ stdenvNoCC
, lib
, runCommand
, fetchgit
, fetchurl
, fetchFromGitHub
, dockerTools
, ansible
,
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
* ANSIBLE_COLLECTIONS_PATH = callPackage ./ansible-collections.nix {};
*/
let
  collectionSources = import ../_sources/generated.nix { inherit fetchgit fetchurl fetchFromGitHub dockerTools; };

  installCollections =
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: value: installCollection name)
        (lib.filterAttrs (n: v: lib.hasPrefix "collection-" n) collectionSources));
  installRoles =
    lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value: installRole name) (lib.filterAttrs (n: v: lib.hasPrefix "role-" n) collectionSources));

  installCollection = name: ''
    ln -sf ${collection name}/ansible_collections/* "''${ANSIBLE_COLLECTIONS_PATHS}"
  '';
  installRole = name: ''
    ln -sf ${role name}/roles/* "''${ANSIBLE_ROLES_PATH}"
  '';

  collection = name:
    stdenvNoCC.mkDerivation {
      inherit (collectionSources."${name}") pname version src;

      phases = [ "installPhase" ];

      installPhase = ''
        mkdir -p $out
        ANSIBLE_HOME="''$TMPDIR" ${ansible}/bin/ansible-galaxy collection install $src -p $out
      '';
    };
  role = name:
    stdenvNoCC.mkDerivation rec {
      pname = collectionSources."${name}".aname;
      inherit (collectionSources."${name}") version src;

      phases = [ "unpackPhase" "installPhase" ];

      installPhase = ''
        mkdir -p $out/roles/${pname}
        cp -r ./* $out/roles/${pname}/
        echo "version: ${version}" > $out/roles/${pname}/meta/.galaxy_install_info
      '';
    };
in
runCommand "ansible-collections" { } ''
  mkdir -p $out/{ansible_collections,roles}
  export HOME=./
  export ANSIBLE_COLLECTIONS_PATHS=$out/ansible_collections
  export ANSIBLE_ROLES_PATH=$out/roles
  ${installCollections}
  ${installRoles}
''

