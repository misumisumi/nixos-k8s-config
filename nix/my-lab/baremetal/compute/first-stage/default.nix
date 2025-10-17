{ self, ... }:
{
  imports = [
    self.nixosModules.netboot
    ../_init
    ./infiniband.nix
    ./powermanegement.nix
    ./second-stage-boot.nix
  ];
}
