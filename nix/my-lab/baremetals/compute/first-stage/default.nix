{ self, pkgs, ... }:
{
  imports = [
    self.nixosModules.netboot
    self.nixosModules.static
    ../../_init/settings/console
    ../../_init/settings/locale
    ../../_init/settings/nix
    ../../_init/settings/security
    ../_init/hardware-configuration.nix
    ./infiniband.nix
    ./network.nix
    ./second-stage-boot.nix
    ./ssh.nix
  ];
}
