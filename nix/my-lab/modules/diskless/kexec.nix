{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.services.diskless.kexec;
  inherit (lib)
    mkIf
    mkOption
    mkEnableOption
    optionalString
    optionalAttrs
    ;
  inherit (lib.types) str;

  fetchAndKexec =
    {
      serverURL,
      imageFile ? "",
      imageMetaData ? "",
      useBoardSerial ? false,
      interface ? "",
      extraCondition ? "",
    }:
    let
      curl = if interface != "" then "curl --interface=${interface}" else "curl";
    in
    pkgs.writeShellScriptBin "fetch-and-kexec" (
      optionalString (imageFile != "") ''
        IMAGE_URL="${serverURL}/images/${imageFile}"
      ''
      + optionalString (imageMetaData != "") ''
        IMAGE_JSON_URL="${serverURL}/${imageMetaData}"
        IS_DOWNLOADED=$(${curl} -s -o "/tmp/image-metadata.json" -w "%{http_code}" "$IMAGE_JSON_URL")
        if [ "$IS_DOWNLOADED" -ne 200 ]; then
          echo "Image metadata not found at $IMAGE_JSON_URL."
          exit 1
        fi
          ${
            if extraCondition != "" then
              extraCondition
            else if useBoardSerial then
              ''
                SERIAL_NUMBER=${pkgs.dmidecode}/bin/dmidecode -t baseboard | ${pkgs.gnugrep}/bin/grep 'Serial Number' | ${pkgs.coreutils}/bin/cut -d' ' -f3
                if [ -z "$SERIAL_NUMBER" ]; then
                  echo "Failed to get board serial number."
                  exit 1
                fi
                IMAGE_FILE=$(jq --arg serial "$SERIAL_NUMBER" 'to_entries[] | select(.value.serial_number == $serial) | .value.image' /tmp/image-metadata.json)
              ''
            else
              ''
                MAC_ADDRESS=$(cat /sys/class/net/${interface}/address)
                IMAGE_FILE=$(jq --arg mac_address "$MAC_ADDRESS" 'to_entries[] | select(.value.mac_address == $mac_address) | .value.image' /tmp/image-metadata.json)
              ''
          }
        if [ -z "$IMAGE_FILE" ]; then
          echo "No matching image metadata found."
          exit 1
        fi
        IMAGE_URL="${serverURL}/images/$IMAGE_FILE"
      ''
      + ''
        OUTPUT_PATH="/tmp/kexec-image.tar.gz"

        IS_DOWNLOADED=$(${curl} -s -o "$OUTPUT_PATH" -w "%{http_code}" "$IMAGE_URL")
        if [ "$IS_DOWNLOADED" -ne 200 ]; then
          echo "Boot image for $HOSTNAME not found at $IMAGE_URL."
          exit 1
        fi

        ${pkgs.gnutar}/bin/tar -xzf "$OUTPUT_PATH" -C "/tmp"
        /tmp/kexec/run
      ''
    );
in
{
  options = {
    services.diskless.kexec = {
      enable = mkEnableOption "Service for diskless system";
      serverURL = mkOption {
        type = str;
        default = "";
        example = "http://ipxe-server.local";
        description = ''
          URL of the server hosting the boot images and metadata.
          Images are expected to be in the "images/" subdirectory.
        '';
      };
      imageFile = mkOption {
        type = str;
        default = "";
        description = "Name of the boot image to fetch for this system.";
      };
      imageMetaData = mkOption {
        type = str;
        default = "";
        example = "image.json";
        description = "Metadata json file name for the boot image.";
      };
      interface = mkOption {
        type = str;
        default = "";
        description = ''
          Interface name or ip address or hostname to use for diskless booting.
          For more infomation, see "man curl".
        '';
      };
      useBoardSerial = mkEnableOption "Use the local board serial number to select the image from metadata.";
      extraCondtion = mkOption {
        type = str;
        default = "";
        description = ''
          Extra shell commands to run when fetching the image metadata.
          Needed to set the IMAGE_FILE variable.
        '';
      };
      autoRun = mkEnableOption "Automatically start the diskless boot service on boot.";
    };
  };
  config = mkIf cfg.enable (
    let
      kexec-run = fetchAndKexec {
        inherit (cfg)
          serverURL
          imageFile
          imageMetaData
          interface
          useBoardSerial
          extraCondition
          ;
      };
    in
    {
      environment.systemPackages = [
        kexec-run
      ];
      systemd.services.kexec-run = {
        description = "Second Stage Kexec Booting Service";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${kexec-run}/bin/second-stage-boot";
        };
      }
      // optionalAttrs cfg.autoRun {
        wantedBy = [
          "multi-user.target"
        ];
        wants = [
          "network-online.target"
        ];
      };
    }
  );
}
