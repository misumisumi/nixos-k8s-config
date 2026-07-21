{ pkgs, config, ... }:
{
  virtualisation.lxc.templates."keepalivedVaultVars" = {
    enable = true;
    target = config.services.keepalived.secretFile;
    template = pkgs.writeText "keepalived-vault.env.tpl" ''
      {% set num = container.name | cut:"vault" | integer %}
      VAULT_PRIORITY={{ 220 - (20 * num) }}
    '';
    when = [ "create" ];
  };
}
