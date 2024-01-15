{ workspace
, ...
}:
let
  pwd = /. + builtins.getEnv "PWD";
in
{
  deployment.keys = {
    "coredns-kube.pem" = {
      keyFile = "${pwd}/.kube/${workspace}/coredns/coredns-kube.pem";
      destDir = "/var/lib/secrets/coredns";
      user = "coredns";
    };
    "coredns-kube-key.pem" = {
      keyFile = "${pwd}/.kube/${workspace}/coredns/coredns-kube-key.pem";
      destDir = "/var/lib/secrets/coredns";
      user = "coredns";
    };
    "kube-ca.pem" = {
      keyFile = "${pwd}/.kube/${workspace}/kubernetes/ca.pem";
      destDir = "/var/lib/secrets/coredns";
      user = "coredns";
    };
  };

}
