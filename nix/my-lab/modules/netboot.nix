# from https://github.com/nix-community/nixos-images/blob/main/nix/netboot-installer/module.nix
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
    (modulesPath + "/installer/netboot/netboot.nix")
    (modulesPath + "/profiles/minimal.nix")
  ];
  netboot.squashfsCompression = "zstd -Xcompression-level 19";
  services.getty.autologinUser = lib.mkForce "${user}";

  system.build.netbootImage = pkgs.symlinkJoin {
    name = "netboot";
    paths = with config.system.build; [
      netbootRamdisk
      kernel
      (pkgs.runCommand "kernel-params" { } ''
        mkdir -p $out
        ln -s "${config.system.build.toplevel}/kernel-params" $out/kernel-params
        ln -s "${config.system.build.toplevel}/init" $out/init
        ln -s "${config.system.build.netbootIpxeScript}/netboot.ipxe" $out/
      '')
    ];
    preferLocalBuild = true;
  };
}
