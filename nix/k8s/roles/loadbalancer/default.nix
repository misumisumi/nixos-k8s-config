{
  lib,
  inputs,
  modulesPath,
  static,
  tag,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    mkForce
    imap1
    ;
in
{
  image.modules = mkForce {
    lxc = inputs.homelab-modules.nixosModules.lxc-container;
    lxc-metadata = {
      imports = [
        "${modulesPath}/virtualisation/lxc-image-metadata.nix"
        ./keepalived.env.tpl.nix
      ];
    };
  };
  imports = [ ../share/settings ];

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
          ${concatStringsSep "\n  " (
            imap1 (i: ip: "server controlplane${toString i} ${ip}:6443") static.nodes.controlplane.nodeIPs
          )}
      '';
    };

    keepalived = {
      enable = true;
      secretFile = "/var/keys/keepalived.env";
      vrrpInstances.k8s = {
        # TODO: at least basic (hardcoded) auth or other protective measures
        interface = "enp5s0";
        virtualRouterId = 42;
        virtualIps = [
          {
            addr = static.k8s.settings.apiserverAddress;
          }
        ];
        extraConfig = ''
          priority ''${K8S_PRIORITY}
          authentication {
              auth_type PASS
              auth_pass k8s-vrrp
          }
        '';
      };
    };
  };

  boot.kernel.sysctl."net.ipv4.ip_nonlocal_bind" = true;

  networking = {
    hostName = "${tag}";
    firewall = {
      allowedTCPPorts = [ 443 ];
      extraCommands = "iptables -A INPUT -p vrrp -j ACCEPT";
      extraStopCommands = "iptables -D INPUT -p vrrp -j ACCEPT || true";
    };
  };
}
