{ pkgs, ... }:
let
  secondStageBoot = pkgs.writeShellScriptBin "second-stage-boot" ''
    HOSTNAME=$(hostname)
    BOOT_IMAGE="http://homelab-ipxe-server.local/second-stage-images/$HOSTNAME-boot-image.tar.gz"
    OUTPUT_PATH="/tmp/boot-image.tar.gz"

    IS_DOWNLOADED=$(curl -s -o "$OUTPUT_PATH" -w "%{http_code}" "$BOOT_IMAGE")

    if [ "$IS_DOWNLOADED" -ne 200 ]; then
      echo "Boot image for $HOSTNAME not found at $BOOT_IMAGE."
      exit 1
    fi

    ${pkgs.gnutar}/bin/tar -xzf "$OUTPUT_PATH" -C "/tmp"

    /tmp/kexec/run
  '';
in
{
  systemd.services.second-stage-booting = {
    description = "Second Stage Kexec Booting Service";
    wantedBy = [
      "multi-user.target"
    ];
    wants = [
      "network-online.target"
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${secondStageBoot}/bin/second-stage-boot";
    };
  };
}
