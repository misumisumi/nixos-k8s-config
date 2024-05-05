{ ... }:
{
  imports = [
    ./boot.nix
    ./initrd.nix
    ./tmpfiles.nix
    ./zfs.nix
  ];
}
