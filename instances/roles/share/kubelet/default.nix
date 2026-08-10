{
  lib,
  pkgs,
  config,
  static,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    concatMapStrings
    mkDefault
    mkForce
    splitString
    take
    ;
  inherit (static.k8s.settings) serviceClusterIpRange;
in
{
  imports = [
    ./certs.nix
    ./network.nix
  ];

  #NOTE: needed for mounting cephfs and rbd volumes in pods
  boot.kernelModules = [
    "ceph"
    "rbd"
  ];
  #NOTE: https://github.com/rook/rook/issues/10110#issuecomment-1464898937
  systemd.services.containerd.serviceConfig.LimitNOFILE = mkForce "1048576";

  services.kubernetes = {
    addons.dns.enable = false;
    inherit (static.k8s.settings) apiserverAddress clusterCidr;
    apiserver.serviceClusterIpRange = serviceClusterIpRange;
    kubelet = rec {
      enable = true;
      clusterDns = mkDefault [
        "${concatStringsSep "." ((take 3 (splitString "." serviceClusterIpRange)) ++ [ "254" ])}"
      ];
      unschedulable = false;
      kubeconfig = {
        caFile = clientCaFile;
        certFile = tlsCertFile;
        keyFile = tlsKeyFile;
        server = "https://${config.services.kubernetes.apiserverAddress}";
      };
      clientCaFile = "/etc/kubernetes/pki/ca.pem";
      tlsCertFile = "/etc/kubernetes/pki/kubelet.pem";
      tlsKeyFile = "/etc/kubernetes/pki/kubelet-key.pem";
    };
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
  #NOTE: Avoid removing packages managed outside of nixos
  systemd.services.kubelet.preStart = mkForce ''
    ${concatMapStrings (img: ''
      echo "Seeding container image: ${img}"
      ${
        if (lib.hasSuffix "gz" img) then
          ''${pkgs.gzip}/bin/zcat "${img}" | ${pkgs.containerd}/bin/ctr -n k8s.io image import -''
        else
          ''${pkgs.coreutils}/bin/cat "${img}" | ${pkgs.containerd}/bin/ctr -n k8s.io image import -''
      }
    '') config.services.kubernetes.kubelet.seedDockerImages}

    find /opt/cni/bin -type l -exec rm {} \; || true
    ${concatMapStrings (package: ''
      echo "Linking cni package: ${package}"
      ln -fs ${package}/bin/* /opt/cni/bin
    '') config.services.kubernetes.kubelet.cni.packages}
  '';
}
