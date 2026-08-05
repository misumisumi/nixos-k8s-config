{ lib, static, ... }:
let
  inherit (lib)
    concatStringsSep
    filter
    flatten
    imap1
    mkDefault
    mkForce
    splitString
    take
    ;
  inherit (static.k8s.settings) serviceClusterIpRange;

  nodes = flatten (
    map (role: imap1 (i: ip: "${ip} ${role}${toString i}") static.nodes.${role}.nodeIPs) (
      filter (role: static.nodes ? ${role}) [
        "etcd"
        "controlplane"
        "worker"
        "app-worker"
        "ceph-worker"
        "piraeus-worker"
      ]
    )
  );
in
{
  systemd.services."systemd-hostnamed".environment = mkForce { };
  services = {
    kubernetes = {
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
      enable = false;
      checkReversePath = "loose";
      trustedInterfaces = [
        "cilium+"
        "lxc+"
      ];
      allowedUDPPorts = [
        6081
        8472
      ];
      allowedTCPPorts = [
        4240
        4244
      ];
    };
    extraHosts = ''
      ${concatStringsSep "\n" nodes}
    '';
  };
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
}
