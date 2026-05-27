{ lib, static, ... }:
let
  inherit (lib) concatImapStringsSep;
  inherit (static) etcd k8s;
  inherit (k8s.settings) clusterCidr;
in
{
  imports = [
    ./containerd.nix
    ./coredns.nix
  ];
  services.kubernetes.clusterCidr = clusterCidr;
  networking.extraHosts =
    (concatImapStringsSep "\n" (i: ip: "${ip} etcd${i}") etcd.nodeIPs)
    + (concatImapStringsSep "\n" (i: ip: "${ip} controlplane${i}") k8s.controlplane.nodeIPs)
    + (concatImapStringsSep "\n" (i: ip: "${ip} worker${i}") k8s.worker.nodeIPs);
}
