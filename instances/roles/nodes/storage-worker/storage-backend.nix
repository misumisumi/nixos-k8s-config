{
  lib,
  pkgs,
  ...
}:
{
  boot = {
    extraModulePackages = [ pkgs.drbd9-dkms ];
    kernelModules = [
      "ceph"
      "rbd"
      "drbd"
    ];
  };
  # https://github.com/rook/rook/issues/10110#issuecomment-1464898937
  systemd.services.containerd.serviceConfig.LimitNOFILE = lib.mkForce "1048576";

  networking = {
    firewall.allowedTCPPorts = [
      3300 # rook/ceph
      6789 # rook/ceph
      8443 # rook/ceph
    ];
    firewall.allowedTCPPortRanges = [
      {
        # for ceph OSD
        from = 6800;
        to = 7300;
      }
    ];
  };
}
