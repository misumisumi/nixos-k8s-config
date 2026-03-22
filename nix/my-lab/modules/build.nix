{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.system.build;

  inherit (lib) mkForce mkOption types;
in
{
  options = {
    system.build.extraContents = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            source = mkOption { type = types.path; };
            target = mkOption { type = types.path; };
          };
        }
      );
      default = [ ];
    };

  };
  config = {
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
          ++ cfg.extraContents;
        }
      );

      tarball = mkForce (
        pkgs.callPackage "${pkgs.path}/nixos/lib/make-system-tarball.nix" {
          fileName = config.image.baseName;
          extraArgs = "--owner=0";

          storeContents = [
            {
              object = config.system.build.toplevel;
              symlink = "none";
            }
          ];

          contents = [
            {
              source = config.system.build.toplevel + "/init";
              target = "/sbin/init";
            }
          ]
          ++ cfg.extraContents;

          extraCommands = "mkdir -p proc sys dev";
        }
      );
    };
  };
}
