{ modulesPath, hostname, ... }:
let
  inherit (import ../../utils.nix { inherit hostname; }) label;
in
{
  imports = [
    (modulesPath + "/installer/netboot/netboot-minimal.nix")
    # ./hardware-configuration.nix
    ./${label}-network.nix
  ];
}
