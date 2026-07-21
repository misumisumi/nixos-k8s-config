{ pkgs, config, ... }:
{
  virtualisation.lxc.templates."keepalivedVars" = {
    enable = true;
    target = config.services.keepalived.secretFile;
    template = pkgs.writeText "keepalived.env.tpl" ''
      {% set num = container.name | cut:"loadbalancer" | integer %}
      K8S_PRIORITY={{ 220 - (20 * num) }}
    '';
    when = [ "create" ];
  };
}
