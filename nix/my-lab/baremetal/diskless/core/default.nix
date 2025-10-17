{
  imports = [
    ../../_init/apps/pkgs
    ../../_init/apps/virtualization/incus
    ../../_init/settings
    ./hardware-configuration.nix
    ./netboot.nix
    ./powermanegement.nix
  ];
}
