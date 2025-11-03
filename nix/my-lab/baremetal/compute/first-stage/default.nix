{ self, ... }:
{
  imports = [
    self.nixosModules.netboot
    ../_init
    ../../_init/settings/user/limited
    ./infiniband.nix
    ./network.nix
    # ./second-stage-boot.nix
  ];
}
