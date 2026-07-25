{
  lib,
  inputs,
  static,
  modulesPath,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    flatten
    imap1
    mkForce
    ;
  nodes = flatten (
    map (role: imap1 (i: ip: "${role}${toString i} ${ip}") static.nodes.${role}.nodeIPs) [
      "etcd"
      "controlplane"
      "worker"
    ]
  );
in
{
  imports = [
    ../../share/settings
    ./certs.nix
  ];

  image.modules = mkForce {
    lxc = inputs.homelab-modules.nixosModules.lxc-container;
    lxc-metadata = {
      imports = [
        "${modulesPath}/virtualisation/lxc-image-metadata.nix"
        ./templates/etcd.conf.tpl.nix
      ];
    };
  };

  networking = {
    firewall.allowedTCPPorts = [
      2379
      2380
    ];
  };
  networking.extraHosts = concatStringsSep "\n" nodes;

  services.etcd = {
    enable = true;
    extraConf = {
      CONFIG_FILE = "/etc/etcd.conf";
    };
  };

  systemd.services.etcd = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
  };
}
