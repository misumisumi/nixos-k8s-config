# lib extension: CIDR netmask helpers
# Used via `lib.extend (import ./lib.nix)`.
final: prev: {
  removeNetmask = addr: final.head (final.splitString "/" addr);

  getNetmask =
    addr:
    let
      prefix = final.toInt (final.last (final.splitString "/" addr));
      pow2 = k: final.foldl' (acc: _: acc * 2) 1 (final.range 1 k);
      octet = ones: if ones <= 0 then 0 else (pow2 8) - (pow2 (8 - ones));
      octets = map (i: octet (final.max 0 (final.min 8 (prefix - i * 8)))) (final.range 0 3);
    in
    final.concatStringsSep "." (map toString octets);

  # Merge all `<dir>/<group>/<file>` static definitions under `dir` into one attrset.
  # Each group directory is expected to contain a per-group static file (e.g. `static_dev.nix`).
  mergeStatic =
    dir: file:
    let
      inherit (builtins)
        attrNames
        filter
        pathExists
        readDir
        ;
      entries = readDir dir;
      groups = filter (n: entries.${n} == "directory") (attrNames entries);
      files = map (g: dir + "/${g}/${file}") groups;
    in
    final.foldl (acc: p: if pathExists p then final.recursiveUpdate acc (import p) else acc) { } files;
}
