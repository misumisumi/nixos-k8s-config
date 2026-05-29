{ lib, static, ... }:
let
  inherit (lib) concatImapStringsSep mapAttrsToList concatStringsSep;
  inherit (static) etcd k8s;
  inherit (k8s.settings) clusterCidr;
in
{
  services.kubernetes.clusterCidr = clusterCidr;
  networking.extraHosts = ''
    ${concatStringsSep "\n" (mapAttrsToList (k: v: "${v.nodeIP} ${k}") etcd)}
    ${concatImapStringsSep "\n" (i: ip: "${ip} controlplane${toString i}") k8s.controlplane.nodeIPs}
    ${concatImapStringsSep "\n" (i: ip: "${ip} worker${toString i}") k8s.worker.nodeIPs}
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
