{
  pkgs,
  static,
  hostSecretPath,
  config,
  ...
}:
let
  inherit (static.liveimg.second-image) manageSegment;
  inherit (import "${hostSecretPath}/secrets.nix") webhookURL;

  script = ''
    uuid=$(cat /sys/class/dmi/id/product_uuid)
    manageIP=$(ip route show to ${manageSegment} | grep -E "enp|eth" | grep -oP 'src \K[0-9.]+')

    output=""
    while read -r line; do
      name=$(echo "$line" | awk '{print $2}')
      size=$(echo "$line" | awk '{print $3}' | numfmt --to=iec --suffix=B)
      disk_uuid=$(echo "$line" | awk '{print $4}')
      [ -z "$disk_uuid" ] && disk_uuid="-"

      ids=$(find /dev/disk/by-id -lname "*/$name" -printf '%f\\n' 2>/dev/null)
      [[ -z "$ids" ]] && ids="-"

      # # フォーマットを整えて出力
      output+="----------------------------------------------------------\n"
      output+="NAME: $name\nUUID: $disk_uuid\nSIZE: $size\nIDs :\n$ids\n"
      output+="----------------------------------------------------------\n"
    done < <(lsblk -b -d -o TYPE,NAME,SIZE,UUID | grep "disk")

    webhook_url="${webhookURL}"

    curl -X POST -H "Content-Type: application/json" -d @- "$webhook_url" <<EOF
    {
      "embeds": [
        {
          "title": "新規登録",
          "description": "れなこが悪いんだよ",
          "color": 5895060,
          "url": "",
          "timestamp": "$(date '+%Y-%m-%dT%H:%M:%S.%3NZ')",
          "fields": [
            {
              "name": "Machine",
              "value": "$(cat /sys/class/dmi/id/product_name)",
              "inline": false
            },
            {
              "name": "UUID",
              "value": "$uuid",
              "inline": false
            },
            {
              "name": "Manage IP",
              "value": "$manageIP",
              "inline": false
            },
            {
              "name": "Disks",
              "value": "$output",
              "inline": false
            }
          ]
        }
      ]
    }
    EOF
  '';
in
{

  systemd.services.regist-machine = {
    wantedBy = [ "multi-user.target" ];
    inherit script;
    path = with pkgs; [
      coreutils
      curl
      gawk
      iproute2
      util-linux
    ];
    environment = {
      TZ = "${config.time.timeZone}";
    };
    serviceConfig = {
      Type = "oneshot";
    };
  };
}
