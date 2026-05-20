{
  self,
  static,
  lib,
  ...
}:
let
  inherit (static.mngr.image-server) manageIP;
in
{
  imports = [ self.nixosModules.diskless ];
  services.diskless.kexec = {
    enable = true;
    serverURL = "http://${manageIP}/kexec";
    metaJSON = "kexec-images.json";
    useUUID = true;
  };
}
