{ self, ... }:
{
  imports = [
    self.nixosModules.kexec
    ../../_init/settings/console
    ../../_init/settings/locale
    ../../_init/settings/nix
    ../../_init/settings/security
    ../_init/hardware-configuration.nix
    ./network.nix
    ./ssh.nix
  ];
}
