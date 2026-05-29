{ lib, static, ... }:
let
  inherit (lib)
    flatten
    imap1
    concatStringsSep
    ;
  inherit (static.k8s.settings) clusterCidr;

  nodes = flatten (
    map (role: imap1 (i: ip: "${ip} ${role}${toString i}") static.nodes.${role}.nodeIPs) [
      "etcd"
      "controlplane"
      "worker"
    ]
  );
in
{
  services.kubernetes.clusterCidr = clusterCidr;
  networking.extraHosts = ''
    ${concatStringsSep "\n" nodes}
  '';
  # rootless環境でのkubernetesの実行
  # INFO: https://kubernetes.io/docs/tasks/administer-cluster/kubelet-in-userns
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
  services.kubernetes.addons.dns = {
    enable = true;
    replicas = 3;
  };
}
