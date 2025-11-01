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
      ./tiny-router
      ./_init/incus/container
    ];
  };
  ipxe-server = lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
      user = "nixos";
      hostname = "ipxe-server";
      inherit
        self
        inputs
        ;
    }; # specialArgs give some args to modules
    modules = [
      ./ipxe-server
      ./_init/incus/container
    ];
  };
}
