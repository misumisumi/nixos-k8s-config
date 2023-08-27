{ pkgs
, name
, ...
}: {
  _module.args = rec {
    inherit (pkgs.callPackage ../../utils/resources.nix { }) resourcesFromHosts;
    inherit (builtins.head (builtins.filter (r: r.name == name) resourcesFromHosts)) ip_address;
    hostname = name;
  };
}
