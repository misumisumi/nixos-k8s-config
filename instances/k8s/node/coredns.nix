{ self
, virtualIP
, nodeIP
, ...
}:
let
  pwd = builtins.toPath (builtins.getEnv "PWD");
in
{
  # For colmena
  deployment.keys = {
    "coredns-kube.pem" = {
      keyFile = "${pwd}/.kube/coredns/coredns-kube.pem";
      destDir = "/var/lib/secrets/coredns";
      user = "coredns";
    };
    "coredns-kube-key.pem" = {
      keyFile = "${pwd}/.kube/coredns/coredns-kube-key.pem";
      destDir = "/var/lib/secrets/coredns";
      user = "coredns";
    };
    "kube-ca.pem" = {
      keyFile = "${pwd}/.kube/kubernetes/ca.pem";
      destDir = "/var/lib/secrets/coredns";
      user = "coredns";
    };
  };

  services.coredns = {
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

  services.kubernetes.kubelet.clusterDns = nodeIP self;

  networking.dhcpcd.denyInterfaces = [ "mynet*" ];
  networking.firewall.interfaces.mynet.allowedTCPPorts = [ 53 ];
  networking.firewall.interfaces.mynet.allowedUDPPorts = [ 53 ];

  users.groups.coredns = { };
  users.users.coredns = {
    group = "coredns";
    isSystemUser = true;
  };
}
