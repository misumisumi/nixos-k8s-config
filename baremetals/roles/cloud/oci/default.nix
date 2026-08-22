{
  lib,
  hostSecretPath,
  isDev,
  ...
}:
let
  inherit (lib) optional;
in
{
  imports = [
    ../share
    ./network.nix
    ./sslh.nix
    ./wireguard.nix
    ./pihole.nix
  ]
  ++ optional (!isDev) ./production
  ++ optional isDev ./develop;

  # sops-nix: ssh ホスト鍵から age 鍵（keys.txt）を生成して秘密を復号。
  # - dev: 事前生成した ssh ホスト鍵をビルド時にイメージへ焼き込み（develop/default.nix）
  # - prod: nixos-anywhere のシークレット転送で ssh ホスト鍵を配置
  sops = {
    defaultSopsFile = hostSecretPath + "/secrets.yaml";
    age = {
      generateKey = true;
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      keyFile = "/etc/sops/age/keys.txt";
    };
  };
}