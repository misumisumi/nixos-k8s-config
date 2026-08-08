{
  inputs,
  lib,
  pkgs,
  secretPath,
  isDev,
  static,
  ...
}:
let
  vaultCA = builtins.readFile (secretPath + "/pki/vault/ca.pem");
in
{
  imports = [
    inputs.homelab-modules.nixosModules.vault-unseal
  ];
  security.pki.certificates = [ vaultCA ];

  environment.systemPackages = with pkgs; [ vault ];

  services.vault.enable = true;
  services.vault-unseal = {
    enable = true;
    secretsFile = "/var/secrets/vault-unseal";
    settings = {
      environment = if isDev then "dev" else "prod";
      check_interval = "15s";
      max_check_interval = "30m";
      vault_nodes = map (ip: "https://${ip}:8200") static.vault.vault.nodeIPs;
      unseal_tokens = [
        "@unseal_token1@"
        "@unseal_token2@"
      ];
      notify = {
        max_elapsed = "2m";
        queue_delay = "60s";
        urls = [
          "discord://@discord_webhook_url@"
        ];
      };
    };
  };

  systemd.services = {
    vault.serviceConfig.ExecStart = lib.mkForce "${pkgs.vault}/bin/vault server -config=/etc/vault/vault.hcl";
    "copy-kubelet-certs" = {
      requiredBy = [ "vault-unseal.service" ];
      before = [ "vault-unseal.service" ];
      script = ''
        ${pkgs.coreutils}/bin/ln -sf "/var/secrets/$(${pkgs.hostname}/bin/hostname)" /var/secrets/vault-unseal
      '';
    };
  };

  # fileSystems."/var/lib/vault" = {
  #   device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_incus_vault";
  #   fsType = "ext4";
  #   autoFormat = true;
  # };

  system.build.extraContents = [
    {
      source = secretPath + "/roles/vault/vault1";
      target = "/var/secrets/vault1";
      user = "root";
      group = "root";
      mode = "0600";
    }
    {
      source = secretPath + "/roles/vault/vault2";
      target = "/var/secrets/vault2";
      user = "root";
      group = "root";
      mode = "0600";
    }
    {
      source = secretPath + "/roles/vault/vault3";
      target = "/var/secrets/vault3";
      user = "root";
      group = "root";
      mode = "0600";
    }
  ];
}
