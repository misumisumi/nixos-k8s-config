{
  lib,
  hostSecretPath,
  ...
}:
{
  imports = [
    ../../share/apps/bash.nix
    ../../share/apps/pkgs.nix
    ../../share/settings/locale.nix
    ../../share/settings/network.nix
    ../../share/settings/system.nix
    ../../share/settings/users.nix
    ../../share/settings/ssh.nix
    ./headscale
    ./network.nix
    ./nginx.nix
    ./oci.nix
    ./pihole.nix
    ./sslh.nix
    ./wireguard.nix
  ];

  services = {
    # nixos-rebuild (nixos-anywhere terraform モジュール) が root で SSH するため、
    # 共有 ssh.nix の prod 設定(no) を prohibit-password に上書きする
    # （root の authorized_keys = sumi@mother は共有 users.nix で設定済み）。
    openssh.settings.PermitRootLogin = lib.mkForce "prohibit-password";
  };

  sops = {
    defaultSopsFile = hostSecretPath + "/secrets.yaml";
    age = {
      generateKey = true;
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      keyFile = "/etc/sops/age/keys.txt";
    };
  };
}
