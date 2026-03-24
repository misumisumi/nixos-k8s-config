{
  imports = [
    ../../../share/apps/bash
    ../../../share/modules/static.nix
    ../../../share/settings/console
    ../../../share/settings/locale
    ../../../share/settings/nix
    ../../../share/settings/security
    ../../../share/settings/user
    ./network.nix
    ./second-stage-boot.nix
    ./ssh.nix
  ];
}
