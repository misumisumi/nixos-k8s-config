{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    optionalString
    ;
  cfg = config.services.vault-unseal;
  jsonFormat = pkgs.formats.json { };
in
{
  options.services.vault-unseal = {
    enable = mkEnableOption "Enable vault-unseal service";
    settings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      description = ''
        Configuration for the vault-unseal.
      '';
    };
    secretsFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        File consisting of lines of the form `varname=value`
        to define variables for the vault-unseal configuration.
      '';
    };
  };
  config = mkIf cfg.enable {
    systemd.services.vault-unseal =
      let
        replaceSecrets = secretFile: out: ''
          while read -r line; do
            key=$(echo "$line" | cut -d= -f1)
            value=$(echo "$line" | cut -d= -f2-)
            ${pkgs.replace-secret}/bin/replace-secret @$key@ <(echo -n "$value") ${out}
          done < ${secretFile}
        '';
        preStart = pkgs.writeShellScript "generate-vault-unseal-yaml" ''
          install -Dm600 ${jsonFormat.generate "vault-unseal.yaml" config.services.vault-unseal.settings} /etc/vault-unseal.yaml
          ${optionalString (
            cfg.secretsFile != null
          ) "${replaceSecrets cfg.secretsFile "/etc/vault-unseal.yaml"}"}
        '';
      in
      {
        description = "Vault unsealing utility";
        documentation = [ "https://github.com/lrstanley/vault-unseal" ];
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];

        serviceConfig = {
          Type = "simple";
          User = "root";
          Group = "root";
          ExecStartPre = "!${preStart}";
          ExecStart = "${pkgs.vault-unseal}/bin/vault-unseal --config /etc/vault-unseal.yaml";
          Restart = "always";
          RestartSec = "10";
          StartLimitInterval = "0";
          TimeoutStopSec = "10s";
          KillMode = "mixed";
          KillSignal = "SIGQUIT";
          PrivateDevices = true;
          ProtectHome = true;
          PrivateTmp = true;
        };
      };
  };
}
