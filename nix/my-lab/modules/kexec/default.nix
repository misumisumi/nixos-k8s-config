{
  user,
  lib,
  pkgs,
  config,
  modulesPath,
  ...
}:
let
  inherit (lib) mkForce;
in
{
  imports = [
    ../build.nix
    (modulesPath + "/installer/netboot/netboot.nix")
    (modulesPath + "/profiles/base.nix")
  ];
  hardware.enableAllHardware = true;
  boot.initrd.compressor = "xz";
  services.getty.autologinUser = mkForce "${user}";

  system.build = {
    netbootRamdisk = mkForce (
      pkgs.makeInitrdNG {
        inherit (config.boot.initrd) compressor compressorArgs;
        prepend = [ "${config.system.build.initialRamdisk}/initrd" ];

        contents = [
          {
            source = config.system.build.squashfsStore;
            target = "/nix-store.squashfs";
          }
        ]
        ++ config.system.build.extraContents;
      }
    );

    # #NOTE: override https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/installer/netboot/netboot.nix
    kexecScript = mkForce (
      pkgs.writeScript "kexec-boot" ''
        #!/usr/bin/env bash

        loadOnly=0

        while [ $# -gt 0 ]; do
          case "$1" in
          --load-only)
            loadOnly=1
            shift
            ;;
          esac
          shift
        done

        if ! kexec -v >/dev/null 2>&1; then
          echo "kexec not found: please install kexec-tools" 2>&1
          exit 1
        fi
        SCRIPT_DIR=$( cd -- "$( dirname -- "''${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
        kexec --load ''${SCRIPT_DIR}/bzImage \
          --initrd=''${SCRIPT_DIR}/initrd.gz \
          --command-line "init=${config.system.build.toplevel}/init ${toString config.boot.kernelParams}"

        if [ "$loadOnly" -eq 0 ]; then
          # Disconnect our background kexec from the terminal
          echo "machine will boot into nixos in 6s..."
          if test -e /dev/kmsg; then
            # this makes logging visible in `dmesg`, or the system console or tools like journald
            exec >/dev/kmsg 2>&1
          else
            exec >/dev/null 2>&1
          fi
          # We will kexec in background so we can cleanly finish the script before the hosts go down.
          # This makes integration with tools like terraform easier.
          nohup sh -c "sleep 6 && kexec -e" &
        else
          echo "waiting 6s before next step..."
          nohup sh -c "sleep 6" &
        fi
      ''
    );

    kexecTarball = mkForce (
      pkgs.callPackage "${toString modulesPath}/../lib/make-system-tarball.nix" {
        fileName = config.image.baseName;
        contents = [
          {
            source = config.system.build.kexecScript;
            target = "/kexec_nixos";
          }
          {
            source = "${config.system.build.netbootRamdisk}/initrd";
            target = "/initrd.gz";
          }
          {
            source = "${config.system.build.kernel}/${config.system.boot.loader.kernelFile}";
            target = "/bzImage";
          }
        ];
      }
    );
  };
}
