{ modulesPath, hostname, lib, ... }:
let
  inherit (import ../../utils/consts.nix { inherit lib; }) label;
in
{
  imports = [
    (modulesPath + "/installer/netboot/netboot-minimal.nix")
    # ./hardware-configuration.nix
    ./${label hostname}-network.nix
  ];
}
