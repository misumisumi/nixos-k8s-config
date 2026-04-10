{
  config,
  modulesPath,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkForce;
in
{
  imports = [
    ./build.nix
    (modulesPath + "/virtualisation/lxc-container.nix")
  ];
  config = {
    system.build.tarball = mkForce (
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
        ++ config.system.build.extraContents;

        extraCommands = "mkdir -p proc sys dev";
      }
    );
  };
}
