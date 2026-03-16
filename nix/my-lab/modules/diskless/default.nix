{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.services.diskless.kexec;
  inherit (lib)
    types
    mkIf
    mkOption
    mkEnableOption
    ;

in
{
  options = {
    services.diskless.kexec = {
      enable = mkEnableOption "Service for diskless system";
      serverURL = mkOption {
        type = types.str;
        default = "";
        example = "http://ipxe-server.local";
        description = ''
          URL of the server hosting the boot images and metadata.
          Images are expected to be in the "images/" subdirectory.
        '';
      };
      imageFile = mkOption {
        type = types.str;
        default = "";
        description = "Name of the boot image to fetch for this system.";
      };
      imageMetaJSON = mkOption {
        type = types.str;
        default = "meta.json";
        example = "meta.json";
        description = "Metadata json file name for the boot image.";
      };
      useUUID = mkEnableOption "Fetch image metadata based on system UUID.";

    };
  };
  config = mkIf cfg.enable (
    let
      kexec-run = pkgs.callPackage ./fetch-and-kexec.nix {
        inherit (cfg)
          serverURL
          imageFile
          imageMetaJSON
          useUUID
          ;
      };
    in
    {
      assertions = [
        {
          assertion = cfg.serverURL != "";
          message = ''
            The "services.diskless.kexec.serverURL" option must be set to the URL of the server hosting the boot images.
          '';
        }
      ];
      environment.systemPackages = [
        kexec-run
      ];
      systemd.services.kexec-run = {
        description = "Second Stage Kexec Booting Service";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${kexec-run}/bin/second-stage-boot";
        };
      };
    }
  );
}
