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
    ../../../share/apps/bash.nix
    ../../../share/apps/pkgs.nix
    ../../../share/settings/console.nix
    ../../../share/settings/locale.nix
    ../../../share/settings/network.nix
    ../../../share/settings/security.nix
    ../../../share/settings/ssh.nix
    ../../../share/settings/system.nix
    ./microvm
  ];
  environment.systemPackages = with pkgs; [
    dig
    ethtool
    socat
    traceroute
  ];
  image.modules = mkForce {
    inherit (self.nixosModules) kexec;
    incus-vm = self + "/modules/incus-virtual-machine.nix";
    lxc-metadata = modulesPath + "/virtualisation/lxc-image-metadata.nix";
  };
}
