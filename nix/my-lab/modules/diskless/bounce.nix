{
  lib,
  writeShellScriptBin,
  gnutar,
  coreutils,
  curl,
  jq,
  serverURL,
  fallBackImage ? "nixos-kexec.tar.xz",
  metaJSON ? "",
  useUUID ? false,
}:
let
  inherit (lib) optionalString;
in
writeShellScriptBin "bounce" (
  ''
    FALLBACK_IMAGE_FILE="${fallBackImage}"
  ''
  + optionalString useUUID ''
    IMAGE_JSON_URL="${serverURL}/${metaJSON}"

    PRODUCT_UUID=$(${coreutils}/bin/cat /sys/class/dmi/id/product_uuid)
    TMP_JSON="/tmp/$(basename $IMAGE_JSON_URL)"
    IS_DOWNLOAD=$(${curl}/bin/curl -s -w "%{http_code}" "$IMAGE_JSON_URL" -o "$TMP_JSON")

    IMAGE_FILE=""
    if [ "$IS_DOWNLOAD" -ne 200 ]; then
      echo "Image metadata not found at $IMAGE_JSON_URL."
    else
      echo "Successfully downloaded image metadata."
      IMAGE_FILE=$(${jq}/bin/jq -r --arg uuid "$PRODUCT_UUID" '.[$uuid] | .image' "$TMP_JSON")
    fi
  ''
  + ''
    if [ -z "$IMAGE_FILE" ]; then
      echo "No matching image metadata found."
      if [ -z "$FALLBACK_IMAGE_FILE" ];then
        echo "No fallback image specified. Exiting."
        exit 1
      else
        echo "Failback IMAGE_FILE=$FALLBACK_IMAGE_FILE to fetch image"
        IMAGE_FILE="$FALLBACK_IMAGE_FILE"
      fi
    fi
    IMAGE_URL="${serverURL}/$IMAGE_FILE"
    OUTPUT_PATH="/tmp/$(basename $IMAGE_URL)"
    [ -f "$OUTPUT_PATH" ] && rm -f "$OUTPUT_PATH"

    echo "Fetching image from $IMAGE_URL..."
    IS_DOWNLOAD=$(${curl}/bin/curl -s -C - --retry 5 --retry-delay 3 --connect-timeout 10 -o "$OUTPUT_PATH" -w "%{http_code}" "$IMAGE_URL")
    if [ "$IS_DOWNLOAD" -ne 200 ]; then
      echo "Failed to download image for $HOSTNAME at $IMAGE_URL."
      exit 1
    fi
    echo "Successfully downloaded image."

    rm -rf "/tmp/kexec"
    mkdir -p "/tmp/kexec"
    ${gnutar}/bin/tar -xf "$OUTPUT_PATH" -C "/tmp/kexec"
    rm -f "$OUTPUT_PATH"
    echo "Loading to kexec image..."
    /tmp/kexec/kexec_nixos
  ''
)
