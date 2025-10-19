{
  self,
  inputs,
  lib,
}:
{
  trigger-container = lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
      user = "nixos";
      hostname = "trigger-server";
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
