{ lib, ... }:
{
  primary-additionalfs = import ./node/primary/additionalfs.nix { inherit lib; };
  test-additionalfs = import ./node/test/additionalfs.nix { inherit lib; };
  # secondary-additionalfs = import ./secondary/additionalfs.nix { inherit lib; };
  # tertiary-additionalfs = import ./tertiary/additionalfs.nix { inherit lib; };
}
