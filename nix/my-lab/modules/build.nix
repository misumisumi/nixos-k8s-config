{
  lib,
  ...
}:
let

  inherit (lib) mkOption types;
in
{
  options = {
    system.build = {
      diskSize = mkOption {
        type = types.str;
        default = "auto";
      };
      extraContents = mkOption {
        type = types.listOf (
          types.submodule {
            options = {
              source = mkOption { type = types.path; };
              target = mkOption { type = types.path; };
              user = mkOption {
                type = types.str;
                default = "root";
              };
              group = mkOption {
                type = types.str;
                default = "root";
              };
              mode = mkOption {
                type = types.str;
                default = "0644";
              };
            };
          }
        );
        default = [ ];
      };
    };
  };
}
