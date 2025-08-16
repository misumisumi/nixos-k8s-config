# rootless環境でのkubernetesの実行
# 参照: https://kubernetes.io/docs/tasks/administer-cluster/kubelet-in-userns/#caveats
{ lib, ... }: {
  virtualisation.containerd = {
    settings = {
      version = 2;
      plugins = {
        "io.containerd.grpc.v1.cri" = {
          disable_apparmor = true;
          restrict_oom_score_adj = true;
          disable_hugetlb_controller = true;
        };
        "io.containerd.grpc.v1.cri.containerd" = {
          snapshotter = "fuse-overlayfs";
        };
        "io.containerd.grpc.v1.cri.containerd.runtimes.runc.options" = {
          SystemdCgroup = false;
        };
      };
    };
  };
  # https://github.com/rook/rook/issues/10110#issuecomment-1464898937
  systemd.services.containerd.serviceConfig.LimitNOFILE = lib.mkForce "1048576";
}
