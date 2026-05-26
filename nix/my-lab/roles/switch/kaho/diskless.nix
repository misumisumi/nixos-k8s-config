{
  inputs,
  static,
  lib,
  ...
}:
let
  inherit (lib) removePrefix;
  inherit (static.mngr.image-server) manageIP;
in
{
  imports = [ inputs.homelab-modules.nixosModules.diskless ];
  services.diskless.kexec = {
    enable = true;
    serverURL = "http://${removePrefix "/24" manageIP}/kexec";
    useUUID = true;
  };
}
