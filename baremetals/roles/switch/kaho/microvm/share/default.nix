{ config, lib, user, ... }:
{
  imports = [
    ../../../../share/settings/locale.nix
    ../../../../share/settings/users.nix
  ];

  networking.firewall.checkReversePath = "loose";

  # nscd (nsncd) は main ルーティングテーブルで動作するため、tenant VRF の
  # DNS (例: 192.168.254.253) を引けない。VRF 内の glibc が /etc/resolv.conf
  # を使って直接解決できるよう無効化する。
  services.nscd.enable = false;
  # nscd を無効化するため、systemd の NSS モジュール読み込みも止める
  # (NixOS の assertion 回避)。hosts は files/dns で解決する。
  system.nssModules = lib.mkForce [ ];
  system.nssDatabases.hosts = lib.mkForce [ "files" "dns" ];

  # systemd 同梱の /etc/sysctl.d/50-default.conf が
  # `net.ipv4.conf.*.rp_filter = 2` を設定する。NixOS は `all`/`default` しか
  # 0 にしないため、ワイルドカード適用時に存在する IF は strict のまま残る
  # (switch 時の systemd-sysctl 再実行で再発する)。ワイルドカード側も 0 にする。
  boot.kernel.sysctl = {
    "net.ipv4.conf.*.rp_filter" = 0;
  };

  system = {
    stateVersion = config.system.nixos.release;
    # NixOS settings
    autoUpgrade = {
      # Allow auto update
      enable = false;
      channel = "https://nixos.org/channels/nixos-unstable";
    };
  };

  users.users = {
    ${user}.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHk5O7TU6kg/BiUeUoYkow1PMsDn+HW/+scedNZouZbf renako@microvm"
    ];
    root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHk5O7TU6kg/BiUeUoYkow1PMsDn+HW/+scedNZouZbf renako@microvm"
    ];
  };
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    startWhenNeeded = false;
    settings = {
      KbdInteractiveAuthentication = true;
      PasswordAuthentication = true;
      X11Forwarding = false;
      PermitRootLogin = "yes";
    };
  };
}
