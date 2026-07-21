{
  lib,
  isDev,
  ...
}:
let
  inherit (lib) optional;
in
{
  imports = [
    ../../share/settings/ssh.nix
    ../share
    ./bgp.nix
    ./incus.nix
    ./network.nix
    ./users.nix
  ]
  ++ optional isDev ./develop;
}
