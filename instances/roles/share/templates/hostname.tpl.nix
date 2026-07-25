{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkForce;
in
{
  #NOTE: Incusによって自動的にインスタンス名=hostnameにするために必要
  virtualisation.lxc.templates."hostname" = {
    enable = config.networking.hostName == "";
    target = "/etc/hostname";
    template = pkgs.writeText "hostname.tpl" "{{ container.name }}";
    when = [
      "create"
      "copy"
    ];
  };
}
