{
  self,
  lib,
  modulesPath,
  ...
}:
let
  inherit (lib) mkForce;
in
{
  imports = [
    self.nixosModules.vlan-aware-vxlan
    ./network.nix
  ];
  image.modules = mkForce {
    inherit (self.nixosModules) kexec;
    lxc = modulesPath + "/virtualisation/lxc-container.nix";
    lxc-metadata = modulesPath + "/virtualisation/lxc-image-metadata.nix";
  };
}
