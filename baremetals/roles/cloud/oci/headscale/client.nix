# OCI 自身の Tailscale クライアント。
# authKeyFile を使わないため、初回登録は手動で行う:
#
#   sudo tailscale up \
#     --login-server=https://hs.oci.misumi-sumi.com \
#     --hostname=oci \
#     --accept-dns=false
#
# 表示された URL をブラウザで開き GitHub 認証するとノードが登録される。
# allocation=sequential のため「最初に登録したノード」が 100.64.0.1 を得る。
# Pi-hole の tailscale0 バインド用に、必ず他ノードより先に登録すること。
{
  lib,
  static,
  group,
  hostname,
  ...
}:
let
  inherit (static.${group}.${hostname}) tailnet;
in
{
  services.tailscale = {
    enable = true;
    openFirewall = true;
    # NOTE: authKeyFile 未指定のため extraUpFlags は自動適用されない。
    # 上記の手動コマンドを初回に実行する（2 回目以降は tailscaled が状態を保持）。
    extraUpFlags = [
      "--login-server=https://${tailnet.host}"
      "--hostname=oci"
      "--accept-dns=false" # OCI 自身は resolved の管理下。Pi-hole ループ回避
    ];
  };
}
