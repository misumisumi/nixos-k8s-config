{
  user,
  lib,
  pkgs,
  config,
  modulesPath,
  ...
}:
let
  inherit (lib)
    mkForce
    concatStringsSep
    concatMapStrings
    optionals
    optionalString
    ;
  inherit (config.system.build) extraContents;

  # The stage-1 initrd only chowns root-owned entries; resolve the root uid and
  # the group id numerically because the initrd has its own minimal user/group
  # database where name-based chown fails. Non-root owners are applied in
  # stage-2 (see system.activationScripts.copy-extra-contents) where the full
  # user/group database exists.
  rootOwnerOf =
    entry: "${toString config.users.users.root.uid}:${toString config.users.groups.${entry.group}.gid}";

  extraContentsDir = pkgs.runCommand "kexec-extra-contents" { } (
    concatMapStrings (entry: ''
      target="$out${entry.target}"
      mkdir -p "$(dirname "$target")"
      cp -L --remove-destination "${entry.source}" "$target"
      chmod ${entry.mode} "$target"
    '') extraContents
  );

  extraContentsCpio = optionals (extraContents != [ ]) [
    (pkgs.runCommand "kexec-extra-contents.cpio"
      {
        nativeBuildInputs = with pkgs; [
          cpio
          zstd
        ];
      }
      ''
        cd "${extraContentsDir}"
        find . -mindepth 1 -print0 | cpio -o -0 -H newc | zstd -T0 > "$out"
      ''
    )
  ];
in
{
  imports = [
    ../build.nix
    (modulesPath + "/installer/netboot/netboot.nix")
    # (modulesPath + "/profiles/base.nix")
    ./profile.nix
  ];
  hardware.enableAllHardware = true;
  boot.initrd = {
    compressor = "zstd";
    systemd.services.copy-extra-contents = {
      description = "Copy Extra Contents to sysroot";
      wantedBy = [ "initrd-switch-root.target" ];
      before = [ "initrd-switch-root.target" ];
      after = [ "sysroot.mount" ];
      unitConfig.DefaultDependencies = false;
      serviceConfig.Type = "oneshot";
      script = concatStringsSep "\n" (
        map (entry: ''
          if [ -e "${entry.target}" ]; then
            mkdir -p "$(dirname "/sysroot${entry.target}")"
            cp -a "${entry.target}" "/sysroot${entry.target}"
            ${optionalString (entry.user == "root") "chown ${rootOwnerOf entry} \"/sysroot${entry.target}\""}
            chmod ${entry.mode} "/sysroot${entry.target}"
          fi
        '') extraContents
      );
    };
  };

  # Non-root owners cannot be resolved in the stage-1 initrd. Apply them in
  # stage-2, after users/groups have been created but before systemd starts.
  system.activationScripts.copy-extra-contents = {
    deps = [ "users" ];
    text = concatStringsSep "\n" (
      map (entry: ''
        if [ -e "${entry.target}" ]; then
          chown ${entry.user}:${entry.group} "${entry.target}"
        fi
      '') (builtins.filter (entry: entry.user != "root") extraContents)
    );
  };

  services.getty.autologinUser = mkForce "${user}";

  system.build = {
    netbootRamdisk = mkForce (
      pkgs.makeInitrdNG {
        inherit (config.boot.initrd) compressor compressorArgs;
        prepend = [ "${config.system.build.initialRamdisk}/initrd" ] ++ extraContentsCpio;

        contents = [
          {
            source = config.system.build.squashfsStore;
            target = "/nix-store.squashfs";
          }
        ];
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
          nohup sh -c "sleep 5 && kexec -e" &
        else
          echo "waiting 5s before next step..."
          nohup sh -c "sleep 5" &
        fi
      ''
    );

    kexecTarball = mkForce (
      pkgs.callPackage "${toString modulesPath}/../lib/make-system-tarball.nix" {
        fileName = config.image.baseName;
        compressCommand = "zstd -6";
        compressionExtension = ".zst";
        extraInputs = [ pkgs.zstd ];
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
  image.extension = mkForce "tar.zst";
}
