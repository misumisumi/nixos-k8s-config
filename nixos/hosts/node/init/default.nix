{ lib
, initial ? false
, ...
}:
{
  imports = [
    ./boot.nix
    ./zfs.nix
  ]
  ++ lib.optional (! initial) ./post-initial.nix
  ;
}
