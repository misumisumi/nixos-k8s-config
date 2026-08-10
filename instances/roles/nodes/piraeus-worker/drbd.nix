{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOverride;
in
{
  boot = {
    extraModulePackages = [ pkgs.drbd9-dkms ];
    kernelModules = [ "drbd" ];
  };
  services = {
    lvm = {
      enable = true;
      package = mkOverride 999 pkgs.lvm2_vdo; # this overrides mkDefault
      boot = {
        thin.enable = true;
        vdo.enable = false;
      };
    };
  };

  # drbd-module-loader が hostPath で /usr/src をマウントするため、
  # ディレクトリを常に存在させる。
  systemd.tmpfiles.rules = [
    "d /usr/src 0755 root root -"
  ];
}
