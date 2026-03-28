{
  self,
  inputs,
  pkgs,
  lib,
  modulesPath,
  ...
}:
let
  inherit (lib) mkForce;
in
{
  imports = [
    inputs.microvm.nixosModules.host
    ../../../share/apps/bash
    ../../../share/apps/pkgs
    ../../../share/settings/console
    ../../../share/settings/locale
    ../../../share/settings/nix
    ../../../share/settings/security
    ../../../share/settings/ssh
    ./microvm.nix
    ./network.nix
  ];
  environment.systemPackages = with pkgs; [
    dig
    ethtool
    socat
    traceroute
  ];
  image.modules = mkForce {
    inherit (self.nixosModules) kexec;
    lxc = modulesPath + "/virtualisation/lxc-container.nix";
    lxc-metadata = modulesPath + "/virtualisation/lxc-image-metadata.nix";
  };
}
