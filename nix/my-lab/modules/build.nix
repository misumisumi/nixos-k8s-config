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
}
