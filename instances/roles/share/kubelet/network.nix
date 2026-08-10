{ lib, static, ... }:
let
  inherit (lib)
    concatStringsSep
    filter
    flatten
    imap1
    mkForce
    ;

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
  networking = {
    #NOTE: donot use NixOS firewall because use Cilium CNI plugin for Kubernetes networking
    # Cilium CNI is able to manage host firewall rules using network policy
    firewall.enable = false;
    extraHosts = ''
      ${concatStringsSep "\n" nodes}
    '';
  };
  services.resolved = {
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
}
