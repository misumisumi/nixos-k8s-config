{ lib
, initial ? false
, ...
}:
{
  imports = [
    ./boot.nix
    ./zfs.nix
  ]
    # TODO: buildする場所によってhostkeyが変わる?
    # ++ lib.optional (! initial) ./post-initial.nix
  ;
}
