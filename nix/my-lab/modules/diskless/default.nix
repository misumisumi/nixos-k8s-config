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
      fallBackImage = mkOption {
        type = types.str;
        default = "nixos-kexec.tar.gz";
        description = "Name of the fallback boot image to fetch for this system.";
      };
      imageMetaJSON = mkOption {
        type = types.str;
        default = "meta.json";
        example = "meta.json";
        description = "Metadata json file name for the boot image.";
      };
      useUUID = mkEnableOption "Fetch image metadata based on system UUID.";
      waitTime = mkOption {
        type = types.int;
        default = 5;
        description = "Time in seconds to wait before attempting to fetch the image and kexec. Useful for ensuring network connectivity is established.";
      };
    };
  };
  config = mkIf cfg.enable (
    let
      fetch-and-kexec = pkgs.callPackage ./fetch-and-kexec.nix {
        inherit (cfg)
          serverURL
          fallBackImage
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
        fetch-and-kexec
      ];
      systemd.services."auto-kexec" = {
        description = "Fetch and kexec for live booting diskless system";
        #NOTE: for modules/kexec/kexec-run.sh
        path = with pkgs; [
          coreutils
          cpio
          gzip
          bash
          util-linux
        ];
        wantedBy = [ "multi-user.target" ];
        wants = [
          "multi-user.target"
          "network-online.target"
        ];
        after = [
          "multi-user.target"
          "network-online.target"
        ];
        serviceConfig = {
          Type = "oneshot";
          ExecStartPre = "${pkgs.coreutils}/bin/sleep ${toString cfg.waitTime}";
          ExecStart = "${fetch-and-kexec}/bin/fetch-and-kexec --load-only";
          ExecStartPost = "${pkgs.systemd}/bin/systemctl kexec";
        };
      };
    }
  );
}
