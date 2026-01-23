{ self, ... }:
{
  imports = [
    ./network.nix
    ./bgp.nix
  ];
}
