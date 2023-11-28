{ modulesPath
, hostname
, lib
, config
, pkgs
, ...
}:
let
  inherit (import ../../../utils/consts.nix { inherit lib; }) label;
in
{
  imports = [
    (modulesPath + "/installer/netboot/netboot-minimal.nix")
    # ./hardware-configuration.nix
    ./${label hostname}-network.nix
  ];
  # From https://github.com/nix-community/nixos-images/blob/8cddbac8c61437f1f412cae48ada7d5896ee46d6/nix/netboot-installer/module.nix
  system.build.netboot = pkgs.symlinkJoin {
    name = "netboot";
    paths = with config.system.build; [
      netbootRamdisk
      kernel
      (pkgs.runCommand "kernel-params" { } ''
        mkdir -p $out
        ln -s "${config.system.build.toplevel}/kernel-params" $out/kernel-params
        ln -s "${config.system.build.toplevel}/init" $out/init
      '')
    ];
    preferLocalBuild = true;
  };
}

