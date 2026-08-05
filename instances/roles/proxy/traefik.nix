{
  lib,
  static,
  ...
}:
let
  inherit (lib) mkForce;
in
{
  services.traefik = {
    enable = true;
    staticConfigOptions = {
      global = {
        checkNewVersion = false;
        sendAnonymousUsage = false;
      };
      entryPoints = {
        web = {
          address = ":80";
          http.redirections.entryPoint = {
            to = "websecure";
            scheme = "https";
          };
        };
        websecure.address = ":443";
      };
    };
    dynamicConfigOptions = {
      tcp = {
        routers.k8s-ingress = {
          rule = "HostSNI(`*`)";
          entryPoints = [ "websecure" ];
          service = "k8s-ingress";
          tls.passthrough = true;
        };
        services.k8s-ingress = {
          loadBalancer.servers = [
            {
              address = "${static.k8s.settings.apiserverAddress}:443";
            }
          ];
        };
      };
    };
  };

  networking = {
    nameservers = [
      "172.16.1.1"
    ];
    firewall = {
      allowedTCPPorts = [
        80
        443
      ];
    };
  };
}
