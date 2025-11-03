{ self, ... }:
{
  imports = [
    self.nixosModules.netboot
    ../../_init/settings/console
    ../../_init/settings/locale
    ../../_init/settings/nix
    ../../_init/settings/security
    ../_init/hardware-configuration.nix
    ./infiniband.nix
    ./network.nix
    ./ssh.nix
    # ./second-stage-boot.nix
  ];
}
