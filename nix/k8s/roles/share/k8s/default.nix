{ lib, static, ... }:
let
  inherit (lib)
    concatStringsSep
    flatten
    imap1
    mkDefault
    splitString
    take
    mkForce
    ;
  inherit (static.k8s.settings) serviceClusterIpRange;

  nodes = flatten (
    map (role: imap1 (i: ip: "${ip} ${role}${toString i}") static.nodes.${role}.nodeIPs) [
      "etcd"
      "controlplane"
      "worker"
    ]
  );
in
{
  services = {
    kubernetes = {
      #NOTE: CoreDNS install using nixidy
      addons.dns.enable = false;
      inherit (static.k8s.settings) apiserverAddress clusterCidr;
      apiserver.serviceClusterIpRange = serviceClusterIpRange;
      kubelet.clusterDns = mkDefault [
        "${concatStringsSep "." ((take 3 (splitString "." serviceClusterIpRange)) ++ [ "254" ])}"
      ];
    };
    resolved = {
      enable = true;
      settings.Resolve = {
        DNSStubListener = false;
        FallbackDNS = [
          "1.1.1.1"
          "2606:4700:4700::1111"
          "8.8.8.8"
          "2001:4860:4860::8888"
        ];
      };
    };
  };
  networking = {
    firewall = {
      checkReversePath = "loose";
      #NOTE: for cilium
      trustedInterfaces = [
        "cilium_host"
        "cilium_net"
        "cilium_vxlan"
        "lxc+"
      ];
    };
    extraHosts = ''
      ${concatStringsSep "\n" nodes}
    '';
  };
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
  # services.kubernetes = {
  #   addonManager.enable = true;
  #   addons.dns = {
  #     enable = true;
  #     replicas = 2;
  #   };
  # };
}
