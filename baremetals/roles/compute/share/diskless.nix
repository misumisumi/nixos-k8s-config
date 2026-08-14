{
  inputs,
  lib,
  static,
  ...
}:
let
  manageIP = lib.removeNetmask static.mngr.image-server.networks.manage.address;
in
{
  imports = [ inputs.homelab-modules.nixosModules.diskless ];
  services.diskless.kexec = {
    enable = true;
    serverURL = "http://${manageIP}/kexec";
    metaJSON = "kexec-images.json";
    useUUID = true;
  };
}
