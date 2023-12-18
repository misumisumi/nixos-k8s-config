{ lib
, initial ? false
, ...
}:
{
  imports = [
    ./boot.nix
    ./zfs.nix
  ]
  ++ lib.optional (! initial) ./initial.nix
  ;
}
