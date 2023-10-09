{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/netboot/netboot-minimal.nix")
  ];
  netboot.squashfsCompression = "zstd -Xcompression-level 6";
}
