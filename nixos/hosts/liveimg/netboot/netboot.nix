{
  user,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/netboot/netboot.nix")
  ];
  netboot.squashfsCompression = "zstd -Xcompression-level 6";
  services.getty.autologinUser = lib.mkForce "${user}";
}
