{ lib, tag }:
{
  const = import ./const.nix { inherit lib; };
  hosts = import ./hosts.nix { inherit tag; };
  tf_state = import ./tf_state.nix { inherit lib; };
}
