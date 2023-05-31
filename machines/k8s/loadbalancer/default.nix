{
  lib,
  resourcesByRole,
  resourcesByRoles,
  virtualIP,
  self,
  ...
}: let
  inherit (import ../../../src/utils.nix) nodeIP;
  backends =
    map
    (r: "server ${r.values.name} ${nodeIP r}:6443")
    (resourcesByRole "controlplane");
  nodes = map (r: "${r.values.ip_address} ${r.values.id}") (resourcesByRoles ["etcd" "controlplane" "loadbalancer" "worker"]);
in {
  services.haproxy = {
    enable = true;
    # TODO: backend healthchecks
    config = ''
      defaults
        timeout connect 10s

      frontend k8s
        mode tcp
        bind *:443
        default_backend controlplanes

      backend controlplanes
        mode tcp
        ${builtins.concatStringsSep "\n  " backends}
    '';
  };

  services.keepalived = {
    enable = true;
    vrrpInstances.k8s = {
      # TODO: at least basic (hardcoded) auth or other protective measures
      interface = "eth0";
      priority =
        # Prioritize loadbalancer1 over loadbalancer2 over loadbalancer3, etc.
        let
          number = lib.strings.toInt (lib.strings.removePrefix "loadbalancer" self.values.name);
        in
          200 - number;
      virtualRouterId = 42;
      virtualIps = [
        {
          addr = virtualIP;
        }
      ];
    };
  };

  boot.kernel.sysctl."net.ipv4.ip_nonlocal_bind" = true;

  networking.firewall.allowedTCPPorts = [443];
  networking.firewall.extraCommands = "iptables -A INPUT -p vrrp -j ACCEPT";
  networking.firewall.extraStopCommands = "iptables -D INPUT -p vrrp -j ACCEPT || true";
  networking.extraHosts = lib.strings.concatMapStrings (x: x + "\n") nodes;
}