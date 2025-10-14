{ tag, ... }:
{
  imports = [
    ./tgtd.nix
    ./vfio.nix
    ./virtualisation.nix
  ];
  config.lib = import ./lib { inherit tag; };
}
