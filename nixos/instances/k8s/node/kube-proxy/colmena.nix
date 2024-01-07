{ workspace
, ...
}:
let
  pwd = builtins.toPath (builtins.getEnv "PWD");
in
{
  deployment.keys = {
    "proxy.pem" = {
      keyFile = "${pwd}/.kube/${workspace}/kubernetes/proxy.pem";
      destDir = "/var/lib/secrets/kubernetes";
      user = "kubernetes";
    };

    "proxy-key.pem" = {
      keyFile = "${pwd}/.kube/${workspace}/kubernetes/proxy-key.pem";
      destDir = "/var/lib/secrets/kubernetes";
      user = "kubernetes";
    };
  };
}
