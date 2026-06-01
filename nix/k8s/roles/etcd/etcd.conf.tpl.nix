{
  lib,
  pkgs,
  static,
  config,
  ...
}:
let
  inherit (lib) imap1 concatStringsSep;
  jsonFormat = pkgs.formats.json { };

  etcdServers = imap1 (i: ip: "etcd${toString i}=https://${ip}:2380") static.nodes.etcd.nodeIPs;

  conf = {
    name = "{{ container.name }}";
    advertise-client-urls = "https://{{ devices.eth0['ipv4.address'] }}:2379";
    initial-advertise-peer-urls = "https://{{ devices.eth0['ipv4.address'] }}:2380";
    initial-cluster = concatStringsSep "," etcdServers;
    listen-client-urls = concatStringsSep "," [
      "https://{{ devices.eth0['ipv4.address'] }}:2379"
      "https://127.0.0.1:2379"
    ];
    listen-peer-urls = concatStringsSep "," [
      "https://{{ devices.eth0['ipv4.address'] }}:2380"
      "https://127.0.0.1:2380"
    ];
    peer-transport-security = {
      client-cert-auth = true;
      cert-file = "/etc/kubernetes/pki/etcd/peer.pem";
      key-file = "/etc/kubernetes/pki/etcd/peer-key.pem";
      trusted-ca-file = "/etc/kubernetes/pki/etcd/ca.pem";
    };
    client-transport-security = {
      client-cert-auth = true;
      cert-file = "/etc/kubernetes/pki/etcd/server.pem";
      trusted-ca-file = "/etc/kubernetes/pki/etcd/ca.pem";
      key-file = "/etc/kubernetes/pki/etcd/server-key.pem";
    };
    data-dir = "/var/lib/etcd";
    initial-cluster-state = "new";
    initial-cluster-token = "etcd-cluster";
  };
in
{
  virtualisation.lxc.templates."etcdConf" = {
    enable = true;
    target = config.services.etcd.extraConf.CONFIG_FILE;
    template = jsonFormat.generate "etcd.conf.tpl" conf;
    when = [ "create" ];
  };
}
