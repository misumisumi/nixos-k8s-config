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
      type = "instance";
      inherit
        self
        inputs
        ;
    }; # specialArgs give some args to modules
    modules = [
      ./tiny-router
      ./_init/incus/container
    ];
  };
}
