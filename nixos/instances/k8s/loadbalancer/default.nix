{ lib
, name
, resourcesByRole
, resourcesByRoles
, virtualIP
, ...
}:
let
  controlplanes = map
    (r: "server ${r.values.name} ${r.values.ipv4_address}:6443")
    (resourcesByRole "controlplane" "k8s");
  nodes = map
    (r: "${r.values.ipv4_address} ${builtins.head (builtins.match "^.*([0-9])" r.values.name)}")
    (resourcesByRoles [ "etcd" "controlplane" "loadbalancer" "worker" ] "k8s");
in
{
  imports = [
    ../../init
    ../autoresources.nix
  ];
  services = {
    # haproxyのログの取り方の参考
    # https://blog.amedama.jp/entry/2015/08/19/194522
    # https://qiita.com/saka1_p/items/3634ba70f9ecd74b0860#%E3%81%A8%E3%82%8A%E3%81%82%E3%81%88%E3%81%9A%E3%83%AD%E3%82%B0%E3%82%92%E5%8F%96%E3%82%8C%E3%82%8B%E3%82%88%E3%81%86%E3%81%AB%E3%81%99%E3%82%8B
    rsyslogd = {
      enable = true;
      defaultConfig = ''
        # Provides UDP syslog reception
        $ModLoad imudp
        $UDPServerRun 514
        local2.info                       /var/log/haproxy.log
        local2.* ~
      '';
    };
    logrotate = {
      enable = true;
      settings = {
        "haproxy" = {
          files = [ "/var/log/haproxy.log" ];
          compress = true;
          rotate = 7;
          size = "100M";
          postrotate = ''
            killall -HUP rsyslogd
          '';
        };
      };
    };
    haproxy = {
      enable = true;
      # TODO: backend healthchecks
      config = ''
        defaults
          timeout connect 10s
          timeout client  10s
          timeout server  10s
          log  127.0.0.1 local2

        frontend k8s
          mode tcp
          bind *:443
          default_backend controlplanes

        backend controlplanes
          mode tcp
          ${builtins.concatStringsSep "\n  " controlplanes}
      '';
    };

    keepalived = {
      enable = true;
      vrrpInstances.k8s = {
        # TODO: at least basic (hardcoded) auth or other protective measures
        interface = "eth0";
        priority =
          # Prioritize loadbalancer1 over loadbalancer2 over loadbalancer3, etc.
          let
            number = lib.strings.toInt (lib.strings.removePrefix "loadbalancer" name);
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
  };

  boot.kernel.sysctl."net.ipv4.ip_nonlocal_bind" = true;

  networking = {
    firewall = {
      allowedTCPPorts = [ 443 ];
      extraCommands = "iptables -A INPUT -p vrrp -j ACCEPT";
      extraStopCommands = "iptables -D INPUT -p vrrp -j ACCEPT || true";
    };
    extraHosts = lib.strings.concatMapStrings (x: x + "\n") nodes;
  };
}


