{
  self,
  static,
  lib,
  ...
}:
let
  inherit (lib) removePrefix;
  inherit (static.mngr.image-server) manageIP;
in
{
  imports = [ self.nixosModules.diskless ];
  services.diskless.kexec = {
    enable = true;
    serverURL = "http://${removePrefix "/24" manageIP}/kexec";
    fallBackImage = "second-image/nixos-kexec.tar.xz";
  };
}
