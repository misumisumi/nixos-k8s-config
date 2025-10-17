{
  user,
  lib,
  pkgs,
  config,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/netboot/netboot-minimal.nix")
  ];
  boot.initrd.compressor = "xz";
  services.getty.autologinUser = lib.mkForce "${user}";

  #NOTE: from https://github.com/nix-community/nixos-images/blob/main/nix/kexec-installer/module.nix
  system.build.kexecImageTarball = pkgs.runCommand "kexec-tarball" { } ''
    mkdir kexec $out
    cp "${config.system.build.netbootRamdisk}/initrd" kexec/initrd
    cp "${config.system.build.kernel}/${config.system.boot.loader.kernelFile}" kexec/bzImage

    tar -czvf $out/${config.networking.hostName}.tar.gz kexec
  '';
}
