# rootless環境でのkubernetesの実行
# 参照: https://kubernetes.io/docs/tasks/administer-cluster/kubelet-in-userns/#caveats
{
  virtualisation.containerd = {
    settings = {
      version = 2;
      plugins."io.containerd.grpc.v1.cri" = {
        disable_apparmor = true;
        restrict_oom_score_adj = true;
        disable_hugetlb_controller = true;
      };
      plugins."io.containerd.grpc.v1.cri.containerd" = {
        snapshotter = "fuse-overlayfs";
      };
      plugins."io.containerd.grpc.v1.cri.containerd.runtimes.runc.options" = {
        SystemdCgroup = false;
      };
    };
  };
}