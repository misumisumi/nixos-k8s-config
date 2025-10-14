{ lib, ... }:
{
  boot.kernelModules = [
    "ceph"
    "rbd"
  ];
  # https://github.com/rook/rook/issues/10110#issuecomment-1464898937
  systemd.services.containerd.serviceConfig.LimitNOFILE = lib.mkForce "1048576";
}
