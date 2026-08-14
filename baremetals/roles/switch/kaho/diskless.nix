{
  inputs,
  lib,
  static,
  ...
}:
let
  inherit (lib) removePrefix;
  manageIP = lib.removeNetmask static.mngr.image-server.networks.manage.address;
in
{
  imports = [ inputs.homelab-modules.nixosModules.diskless ];
  services.diskless.kexec = {
    enable = true;
    serverURL = "http://${removePrefix "/24" manageIP}/kexec";
    useUUID = true;
  };
}
