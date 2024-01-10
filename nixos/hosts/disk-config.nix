{ lib, ... }:
{
  primary-additionalfs = import ./primary/additionalfs.nix { inherit lib; };
  secondary-additionalfs = import ./secondary/additionalfs.nix { inherit lib; };
  tertiary-additionalfs = import ./tertiary/additionalfs.nix { inherit lib; };
}
