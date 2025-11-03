{
  self,
  inputs,
  lib,
}:
{
  tiny-router = lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
      user = "nixos";
      hostname = "tiny-router";
      inherit
        self
        inputs
        ;
    }; # specialArgs give some args to modules
    modules = [
      self.nixosModules.multiple-dnsmasq
      ./tiny-router
      ./_init/incus/container
    ];
  };
}
