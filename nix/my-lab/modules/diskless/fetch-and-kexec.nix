{
  lib,
  writeShellScriptBin,
  gnutar,
  dmidecode,
  curl,
  serverURL,
  fallBackImage ? "nixos-kexec.tar.gz",
  imageMetaJSON ? "",
  useUUID ? false,
}:
let
  inherit (lib) optionalString;
in
writeShellScriptBin "fetch-and-kexec" (
  ''
    FALLBACK_IMAGE_FILE="${fallBackImage}"
  ''
  + optionalString useUUID ''
    IMAGE_JSON_URL="${serverURL}/${imageMetaJSON}"

    SYSTEM_UUID=$(${dmidecode}/bin/dmidecode -t system-uuid)

    IMAGE_FILE=$(${curl}/bin/curl -s -w "%{http_code}" "$IMAGE_JSON_URL" | jq -r --arg uuid "$SYSTEM_UUID" 'to_entries[] | select(.value.system_uuid == $uuid) | .value.image')

    if [ "$IS_DOWNLOADED" -ne 200 ]; then
      echo "Image metadata not found at $IMAGE_JSON_URL."
      IMAGE_FILE=""
    fi
  ''
  + ''
    if [ -z "$IMAGE_FILE" ]; then
      echo "No matching image metadata found."
      echo "Failback IMAGE_FILE=$FALLBACK_IMAGE_FILE to fetch image"
      IMAGE_FILE="$FALLBACK_IMAGE_FILE"
    fi
    IMAGE_URL="${serverURL}/images/$IMAGE_FILE"

    OUTPUT_PATH="/tmp/kexec-image.tar.gz"

    IS_DOWNLOADED=$(${curl}/bin/curl -s -o "$OUTPUT_PATH" -w "%{http_code}" "$IMAGE_URL")
    if [ "$IS_DOWNLOADED" -ne 200 ]; then
      echo "Failed to download image for $HOSTNAME at $IMAGE_URL."
      exit 1
    fi

    ${gnutar}/bin/tar -xzf "$OUTPUT_PATH" -C "/tmp"
    /tmp/kexec/run
  ''
)
