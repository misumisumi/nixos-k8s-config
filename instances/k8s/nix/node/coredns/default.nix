{
  virtualIP,
  nodeIP,
  ...
}:
{
  services = {
    kubernetes.kubelet.clusterDns = [ nodeIP ];
    coredns = {
      enable = true;
      config = ''
        .:53 {
          log
          errors
          kubernetes cluster.local in-addr.arpa ip6.arpa {
            endpoint https://${virtualIP}
            tls /var/lib/secrets/coredns/coredns-kube.pem /var/lib/secrets/coredns/coredns-kube-key.pem /var/lib/secrets/coredns/kube-ca.pem
            fallthrough in-addr.arpa ip6.arpa
            pods verified
          }
          forward . 1.1.1.1:53 1.0.0.1:53
        }
      '';
    };
  };

  networking = {
    dhcpcd.denyInterfaces = [ "mynet*" ];
    firewall.interfaces.mynet.allowedTCPPorts = [ 53 ];
    firewall.interfaces.mynet.allowedUDPPorts = [ 53 ];
  };

  users = {
    groups.coredns = { };
    users.coredns = {
      group = "coredns";
      isSystemUser = true;
    };
  };
}
