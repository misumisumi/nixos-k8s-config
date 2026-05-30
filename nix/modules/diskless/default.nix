{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.services.diskless.kexec;
  inherit (lib)
    mkEnableOption
    mkForce
    mkIf
    mkOption
    types
    ;

in
{
  options = {
    services.diskless.kexec = {
      enable = mkEnableOption "Service for diskless system";
      service.enable = mkEnableOption "Whether to enable the systemd service for fetching and kexecing the boot image.";
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
        default = "";
        description = "Name of the fallback boot image to fetch for this system.";
      };
      metaJSON = mkOption {
        type = types.str;
        default = "kexec-images.json";
        example = "kexec-images.json";
        description = "Metadata json file name for the kexec images.";
      };
      useUUID = mkEnableOption "Fetch image metadata based on system UUID.";
      waitTime = mkOption {
        type = types.int;
        default = 10;
        description = "Time in seconds to wait before attempting to fetch the image and kexec. Useful for ensuring network connectivity is established.";
      };
      webhookURL = mkOption {
        type = types.str;
        default = "";
        description = "Discord webhook URL to send notifications about machine info.";
      };
      manageSegment = mkOption {
        type = types.str;
        default = "";
        description = "IP segment to register the machine to when using the webhookURL option.";
      };
    };
  };
  config = mkIf cfg.enable (
    let
      bounce = pkgs.callPackage ./bounce.nix {
        inherit (cfg)
          serverURL
          fallBackImage
          metaJSON
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
      system.tools = {
        nixos-build-vms.enable = false;
        nixos-enter.enable = false;
        nixos-generate-config.enable = false;
        nixos-install.enable = false;
        nixos-option.enable = false;
        nixos-rebuild.enable = false;
      };
      programs.nano.enable = false;
      fonts = {
        fontconfig.enable = false;
        enableDefaultPackages = false;
      };
      environment = {
        defaultPackages = mkForce [ ];
        systemPackages = [
          bounce
        ];
      };
      systemd.services."auto-bounce" = {
        inherit (cfg.service) enable;
        description = "Fetch and kexec for live booting diskless system";
        #NOTE: for modules/kexec/kexec-run.sh
        path = with pkgs; [
          bash
          gzip
          kexec-tools
          xz
          zstd
        ];
        wantedBy = [ "multi-user.target" ];
        after = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStartPre = "${pkgs.coreutils}/bin/sleep ${toString cfg.waitTime}";
          ExecStart = "${bounce}/bin/bounce --load-only";
          ExecStartPost = "${pkgs.systemd}/bin/systemctl kexec";
        };
      };
    }
  );
}
