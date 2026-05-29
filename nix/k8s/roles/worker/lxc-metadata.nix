{ pkgs, ... }:
{
  #NOTE: Incusによって自動的にインスタンス名=hostnameにするために必要
  virtualisation.lxc.templates."hostname" = {
    enable = true;
    target = "/etc/hostname";
    template = pkgs.writeText "hostname.tpl" "{{ container.name }}";
    when = [ "create" ];
  };
}
