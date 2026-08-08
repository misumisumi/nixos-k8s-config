{
  lib,
  inputs,
  modulesPath,
  static,
  ...
}:
let
  inherit (lib) mkForce;
in
{
  imports = [
    ../share/settings
    ./vault.nix
    ./certs.nix
  ];

  image.modules = mkForce {
    lxc = inputs.homelab-modules.nixosModules.lxc-container;
    lxc-metadata = {
      imports = [
        "${modulesPath}/virtualisation/lxc-image-metadata.nix"
        ./templates/vault-config.tpl.nix
        ./templates/keepalived.tpl.nix
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/secrets 0700 root root -"
  ];

  boot.kernel.sysctl."net.ipv4.ip_nonlocal_bind" = true;

  networking = {
    nftables.enable = true;
    firewall = {
      allowedTCPPorts = [
        8200
        8201
      ];
      extraInputRules = ''
        ip protocol vrrp accept
      '';
    };
  };

  services.keepalived = {
    enable = true;
    secretFile = "/var/keys/keepalived-vault.env";
    vrrpInstances.vault = {
      interface = "enp5s0";
      virtualRouterId = 43;
      virtualIps = [
        {
          addr = static.vault.vault.vip;
        }
      ];
      extraConfig = ''
        priority ''${VAULT_PRIORITY}
        authentication {
            auth_type PASS
            auth_pass vault-vrrp
        }
      '';
    };
  };
}
