{
  self,
  static,
  ...
}:
let
  inherit (static.mngr.image-server) manageIP;
in
{
  imports = [ self.nixosModules.diskless ];
  services.diskless.kexec = {
    enable = true;
    service.enable = true;
    serverURL = "http://${manageIP}/kexec";
    metaJSON = "kexec-images.json";
    useUUID = true;
    fallBackImage = "second-image/nixos-kexec.tar.zst";
  };
}
