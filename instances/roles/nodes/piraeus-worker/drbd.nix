{
  lib,
  pkgs,
  ...
}:
{
  boot = {
    extraModulePackages = [ pkgs.drbd9-dkms ];
    kernelModules = [
      "drbd"
    ];
  };

  # drbd-module-loader が hostPath で /usr/src をマウントするため、
  # ディレクトリを常に存在させる。
  systemd.tmpfiles.rules = [
    "d /usr/src 0755 root root -"
  ];
}
