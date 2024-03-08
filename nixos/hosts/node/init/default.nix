{ lib
, initial ? false
, ...
}:
{
  imports = [
    ./boot.nix
    ./tmpfiles.nix
    ./zfs.nix
  ]
  ++ lib.optional (! initial) ./post-initial.nix
  ;
}
